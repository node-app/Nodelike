//
//  NLContext.h
//  Nodelike
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
