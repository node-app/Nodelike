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

#include "TargetConditionals.h"

#if TARGET_OS_IPHONE 
#import <UIKit/UIKit.h>
#endif 

#import <JavaScriptCore/JavaScriptCore.h>

#import "uv.h"

@interface NLContext : JSContext

#pragma mark Public API

+ (void)attachToContext:(JSContext *)context;

#if TARGET_OS_IPHONE
+ (void)attachToWebView:(UIWebView *)webView;
#endif

+ (uv_loop_t *)eventLoop;

+ (void)runEventLoopSync;
+ (void)runEventLoopAsync;

@end
