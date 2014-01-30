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

+ (void)runBootstrapJavascript:(JSContext *)context {
    JSValue *constructor = [context evaluateScript:[NLNatives source:@"nodelike"]];
    [constructor callWithArguments:@[^(NSString *code) {
        return [JSContext.currentContext evaluateScript:code];
    }]];
}

+ (void)attachToContext:(JSContext *)context {

#ifdef DEBUG
    context.exceptionHandler = ^(JSContext *ctx, JSValue *e) {
        NSLog(@"EXC: %@", e);
    };
#endif
    
    context[@"process"] = @{@"platform": @"darwin",
                            @"argv":     NSProcessInfo.processInfo.arguments,
                            @"env":      NSProcessInfo.processInfo.environment,
                            @"execPath": NSBundle.mainBundle.executablePath,
                            @"_asyncFlags": @{},
                            @"moduleLoadList": @[]};
    
    context[@"process"][@"hrtime"] = ^(JSValue *offset) {
        clock_serv_t cclock;
        mach_timespec_t mts;
        host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);
        clock_get_time(cclock, &mts);
        mach_port_deallocate(mach_task_self(), cclock);
        unsigned int sec  = mts.tv_sec;
        unsigned int nsec = mts.tv_nsec;
        if (!offset.isUndefined) {
            sec  = [offset valueAtIndex:0].toInt32 - sec;
            nsec = [offset valueAtIndex:1].toInt32 - nsec;
        }
        return @[[NSNumber numberWithUnsignedInt:sec], [NSNumber numberWithUnsignedInt:nsec]];
    };
    
    context[@"process"][@"reallyExit"] = ^(NSNumber *code) {
        exit(code.intValue);
    };
    
    context[@"process"][@"_kill"] = ^(NSNumber *pid, NSNumber *sig) {
        kill(pid.intValue, sig.intValue);
    };
    
    context[@"process"][@"nextTick"] = ^(JSValue * cb) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [cb callWithArguments:@[]];
        });
    };
    
    context[@"process"][@"binding"] = ^(NSString *binding) {
        return [NLBinding bindingForIdentifier:binding];
    };
    
    context[@"log"] = ^(id msg) {
        NSLog(@"%@", msg);
    };
    
    [self runBootstrapJavascript:context];

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
