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

@end
