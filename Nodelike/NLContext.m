//
//  NLContext.m
//  NodelikeDemo
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLContext.h"

#import "NLProcess.h"

struct data {
    void *callback, *error, *value, *after;
};

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

    context[@"global"]  = context.globalObject;
    
    context[@"process"] = [NLProcess new];
    
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
    
    context[@"COUNTER_NET_SERVER_CONNECTION"]       = noop;
    context[@"COUNTER_NET_SERVER_CONNECTION_CLOSE"] = noop;
    
}

+ (void)attachToWebView:(UIWebView *)webView {
    [self attachToContext:[webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"]];
}

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

+ (JSContext *)contextForEventRequest:(void *)req {
    return (JSContext *)((__bridge JSValue *)(((struct data *)(((uv_req_t *)req)->data))->callback)).context;
}

+ (void)runEventLoop {
    dispatch_async(NLContext.dispatchQueue, ^{
        uv_run(NLContext.eventLoop, UV_RUN_DEFAULT);
    });
}

+ (JSValue *)createEventRequestOfType:(uv_req_type)type withCallback:(JSValue *)cb
                                   do:(void(^)(uv_loop_t *, void *, bool))task
                                 then:(void(^)(void *, JSContext *))after {
    
    JSContext *context = JSContext.currentContext;

    uv_req_t *req = malloc(uv_req_size(type));

    struct data *data = req->data = malloc(sizeof(struct data));
    data->callback = (void *)CFBridgingRetain(cb);
    data->error = nil;
    data->value = nil;
    data->after = (void *)CFBridgingRetain(after);

    bool async = ![cb isUndefined];

    task(NLContext.eventLoop, req, async);

    if (!async) {

        JSValue *error = data->error != nil ? CFBridgingRelease(data->error) : nil;
        JSValue *value = data->value != nil ? CFBridgingRelease(data->value) : nil;

        free(data);

        if (error == nil) {
            return value;
        } else {
            context.exception = error;
        }

    }

    return nil;

}

+ (void)finishEventRequest:(void *)req do:(void (^)(JSContext *))task {

    JSContext *context = [NLContext contextForEventRequest:req];

    struct data *data = ((uv_req_t *)req)->data;

    task(context);
    
    JSValue *cb    = CFBridgingRelease(data->callback);
    JSValue *error = data->error != nil ? CFBridgingRelease(data->error) : [JSValue valueWithNullInContext:context];
    JSValue *value = data->value != nil ? CFBridgingRelease(data->value) : [JSValue valueWithUndefinedInContext:context];
    
    if (![cb isUndefined]) {
        
        free(data);
        [cb callWithArguments:@[error, value]];
        
    } else if ([error isNull]) {
        
        data->error = nil;
        data->value = (void *)CFBridgingRetain(value);
        
    } else {
        
        data->error = (void *)CFBridgingRetain(error);
        data->value = nil;
        
    }
    
}

+ (void)callSuccessfulEventRequest:(void *)req {
    JSContext *context = [self contextForEventRequest:req];
    struct data *data = ((uv_req_t *)req)->data;
    if (data->after != nil) {
        ((void (^)(void*, JSContext *))CFBridgingRelease(data->after))(req, context);
    }
}

+ (void)setErrorCode:(int)error forEventRequest:(void *)req {
    JSContext *context = [self contextForEventRequest:req];
    NSString *msg = [NSString stringWithUTF8String:uv_strerror(error)];
    [self setError:[JSValue valueWithNewErrorFromMessage:msg inContext:context] forEventRequest:req];
}

+ (void)setError:(JSValue *)error forEventRequest:(void *)req {
    ((struct data *)(((uv_req_t *)req)->data))->error = (void *)CFBridgingRetain(error);
}

+ (void)setValue:(JSValue *)value forEventRequest:(void *)req {
    ((struct data *)(((uv_req_t *)req)->data))->value = (void *)CFBridgingRetain(value);
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
