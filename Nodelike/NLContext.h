//
//  NLContext.h
//  NodelikeDemo
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

#import "uv.h"

@interface NLContext : JSContext

#pragma mark Public API

+ (void)attachToContext:(JSContext *)context;

+ (void)attachToWebView:(UIWebView *)webView;

+ (JSValue *)requireModule:(NSString *)module inContext:(JSContext *)context;

- (JSValue *)requireModule:(NSString *)module;

+ (uv_loop_t *)eventLoop;

+ (void)runEventLoop;

#pragma mark Private

+ (JSContext *)contextForEventRequest:(void *)req;

+ (JSValue *)createEventRequestOfType:(uv_req_type)type withCallback:(JSValue *)cb
                                   do:(void(^)(uv_loop_t *loop, void *req, bool async))task
                                 then:(void(^)(void *, JSContext *))after;

+ (void)finishEventRequest:(void *)req do:(void(^)(JSContext *context))task;

+ (void)callSuccessfulEventRequest:(void *)req;

+ (void)setErrorCode:(int)error forEventRequest:(void *)req;

+ (void)setError:(JSValue *)error forEventRequest:(void *)req;

+ (void)setValue:(JSValue *)value forEventRequest:(void *)req;

@end
