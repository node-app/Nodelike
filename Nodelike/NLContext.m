//
//  NLContext.m
//  Nodelike
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLContext.h"

#import "NLBinding.h"

@implementation NLContext

#pragma mark - JSContext

- (id)init {
    self = [super init];
    [NLContext attachToContext:self];
    return self;
}

- (id)initWithVirtualMachine:(JSVirtualMachine *)virtualMachine {
    self = [super initWithVirtualMachine:virtualMachine];
    [NLContext attachToContext:self];
    return self;
}

+ (NLContext *)currentContext {
    return (NLContext *)[super currentContext];
}

- (JSValue *)evaluateScript:(NSString *)script {
    JSValue *val = [super evaluateScript:script];
    [NLContext runEventLoop];
    return val;
}

#pragma mark - Scope Setup

+ (void)attachToContext:(JSContext *)context {

    [self attachPolyfillsToContext:context];
    
    context[@"global"]  = context.globalObject;

    context[@"process"] = @{@"platform": @"darwin",
                            @"argv":     NSProcessInfo.processInfo.arguments,
                            @"env":      NSProcessInfo.processInfo.environment};
    
    context[@"process"][@"exit"] = ^(NSNumber *code) {
        exit(code.intValue);
    };
    
    context[@"process"][@"nextTick"] = ^(JSValue * cb) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [cb callWithArguments:@[]];
        });
    };
    
    context[@"process"][@"binding"] = ^(NSString *binding) {
        return [NLBinding bindingForIdentifier:binding];
    };
    
    context[@"require"] = ^(NSString *module) {
        return [NLContext requireModule:module inContext:JSContext.currentContext];
    };
    
    context[@"log"] = ^(id msg) {
        NSLog(@"%@", msg);
    };
    
    context[@"Buffer"] = [NLContext requireModule:@"buffer" inContext:context][@"Buffer"];

    JSValue *noop = [context evaluateScript:@"(function(){})"];
    
    context[@"DTRACE_NET_SERVER_CONNECTION"] = noop;
    context[@"DTRACE_NET_STREAM_END"]        = noop;
    context[@"DTRACE_HTTP_CLIENT_REQUEST"]   = noop;
    context[@"DTRACE_HTTP_CLIENT_RESPONSE"]  = noop;
    context[@"DTRACE_HTTP_SERVER_REQUEST"]   = noop;
    context[@"DTRACE_HTTP_SERVER_RESPONSE"]  = noop;
    context[@"DTRACE_NET_SOCKET_READ"]       = noop;
    context[@"DTRACE_NET_SOCKET_WRITE"]      = noop;
    
    context[@"COUNTER_NET_SERVER_CONNECTION"]       = noop;
    context[@"COUNTER_NET_SERVER_CONNECTION_CLOSE"] = noop;
    context[@"COUNTER_HTTP_SERVER_REQUEST"]         = noop;
    context[@"COUNTER_HTTP_SERVER_RESPONSE"]        = noop;
    context[@"COUNTER_HTTP_CLIENT_REQUEST"]         = noop;
    context[@"COUNTER_HTTP_CLIENT_RESPONSE"]        = noop;
    
}

+ (void)attachPolyfillsToContext:(JSContext *)context {

    context[@"Number"][@"isFinite"] = [context evaluateScript:@"(function (value) { return typeof value === 'number' && isFinite(value); })"];

}

#if TARGET_OS_IPHONE
+ (void)attachToWebView:(UIWebView *)webView {
    [self attachToContext:[webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"]];
}
#endif

#pragma mark - Event Handling

+ (uv_loop_t *)eventLoop {
    return uv_default_loop();
}

+ (dispatch_queue_t)dispatchQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        queue = dispatch_queue_create("eventLoop", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (void)runEventLoop {
    dispatch_async(NLContext.dispatchQueue, ^{
        uv_run(NLContext.eventLoop, UV_RUN_DEFAULT);
    });
}

#pragma mark - Module Loading

+ (NSMutableDictionary *)requireCache {
    static NSMutableDictionary *cache;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        cache = [NSMutableDictionary new];
    });
    return cache;
}

- (JSValue *)requireModule:(NSString *)module {

    return [NLContext requireModule:module inContext:self];

}

+ (JSValue *)requireModule:(NSString *)module inContext:(JSContext *)context {
    
    NSMutableDictionary *requireCache = NLContext.requireCache;
    JSValue *cached = [requireCache objectForKey:module];
    
    if (cached != nil) {
        return cached[@"exports"];
    }
    
    NSString* path = [NSBundle.mainBundle pathForResource:module
                                                   ofType:@"js"];
    
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    if (content == nil) {
        NSString *error = [NSString stringWithFormat:@"Cannot find module '%@'", module];
        context.exception = [JSValue valueWithNewErrorFromMessage:error inContext:context];
        return nil;
    }
    
    JSValue *exports = [JSValue valueWithNewObjectInContext:context];
    JSValue *modulev = [JSValue valueWithNewObjectInContext:context];
    modulev[@"exports"] = exports;

    requireCache[module] = modulev;

    NSString *template = @"(function (exports, require, module, __filename, __dirname) {%@\n});";
    NSString *source = [NSString stringWithFormat:template, content];

    JSValue *fn = [context evaluateScript:source];

    [fn callWithArguments:@[exports, context[@"require"], modulev]];

    return modulev[@"exports"];

}

@end
