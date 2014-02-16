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

#import "NSObject+Nodelike.h"

#import "NLBinding.h"

#import "NLNatives.h"

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

#pragma mark - Scope Setup

+ (void)attachToContext:(JSContext *)context {

#ifdef DEBUG
    context.exceptionHandler = ^(JSContext *ctx, JSValue *e) {
        NSLog(@"EXC: %@", e);
    };
#endif
    
    JSValue *process = [JSValue valueWithObject:@{
        @"platform": @"darwin",
        @"argv":     NSProcessInfo.processInfo.arguments,
        @"env":      NSProcessInfo.processInfo.environment,
        @"execPath": NSBundle.mainBundle.executablePath,
        @"_asyncFlags": @{},
        @"moduleLoadList": @[]
    } inContext:context];
    
    // used in Hrtime() below
#define NANOS_PER_SEC 1000000000

    // hrtime exposes libuv's uv_hrtime() high-resolution timer.
    // The value returned by uv_hrtime() is a 64-bit int representing nanoseconds,
    // so this function instead returns an Array with 2 entries representing seconds
    // and nanoseconds, to avoid any integer overflow possibility.
    // Pass in an Array from a previous hrtime() call to instead get a time diff.
    process[@"hrtime"] = ^(JSValue *offset) {
        uint64_t t = uv_hrtime();
        if (!offset.isUndefined && offset.isObject) {
            // return a time diff tuple
            uint64_t seconds = [offset valueAtIndex:0].toInt32;
            uint64_t nanos   = [offset valueAtIndex:1].toInt32;
            t -= (seconds * NANOS_PER_SEC) + nanos;
        }
        return @[[NSNumber numberWithUnsignedInt:t / NANOS_PER_SEC], [NSNumber numberWithUnsignedInt:t % NANOS_PER_SEC]];
    };
    
    process[@"reallyExit"] = ^(NSNumber *code) {
        exit(code.intValue);
    };
    
    process[@"_kill"] = ^(NSNumber *pid, NSNumber *sig) {
        kill(pid.intValue, sig.intValue);
    };
    
    process[@"nextTick"] = ^(JSValue * cb) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [cb callWithArguments:@[]];
        });
    };
    
    process[@"binding"] = ^(NSString *binding) {
        return [NLBinding bindingForIdentifier:binding];
    };
    
    context[@"console"] = @{
        @"log": ^ { NSLog(@"stdio: %@", [JSContext currentArguments]); },
        @"error": ^{ NSLog(@"stderr: %@", [JSContext currentArguments]); }
    };
    
    JSValue *constructor = [context evaluateScript:[NLNatives source:@"nodelike"]];
    [constructor callWithArguments:@[process]];
    
    [context.virtualMachine nodelikeSet:&env_process_object toValue:process];

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

+ (void)runEventLoopSync {
    dispatch_sync(NLContext.dispatchQueue, ^{
        uv_run(NLContext.eventLoop, UV_RUN_DEFAULT);
    });
}

+ (void)runEventLoopAsync {
    dispatch_async(NLContext.dispatchQueue, ^{
        uv_run(NLContext.eventLoop, UV_RUN_DEFAULT);
    });
}

@end
