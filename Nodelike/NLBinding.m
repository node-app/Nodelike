//
//  NLBinding.m
//  Nodelike
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBinding.h"

#import "NLFS.h"
#import "NLConstants.h"
#import "NLSmalloc.h"
#import "NLBuffer.h"
#import "NLCares.h"
#import "NLUV.h"
#import "NLTimer.h"
#import "NLTCP.h"
#import "NLUDP.h"
#import "NLProcess.h"
#import "NLHTTPParser.h"
#import "NLNatives.h"
#import "NLContextify.h"

@implementation NLBinding

+ (NSDictionary *)bindings {
    static NSDictionary *bindings = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        bindings = @{@"fs":           NLFS.class,
                     @"constants":    NLConstants.class,
                     @"smalloc":      NLSmalloc.class,
                     @"buffer":       NLBuffer.class,
                     @"timer_wrap":   NLTimer.class,
                     @"cares_wrap":   NLCares.class,
                     @"tcp_wrap":     NLTCP.class,
                     @"udp_wrap":     NLUDP.class,
                     @"uv":           NLUV.class,
                     @"process_wrap": NLProcess.class,
                     @"http_parser":  NLHTTPParser.class,
                     @"natives":      NLNatives.class,
                     @"contextify":   NLContextify.class};
    });
    return bindings;
}

+ (id)bindingForIdentifier:(NSString *)identifier {
    Class cls = NLBinding.bindings[identifier];
    if (cls) {
        return cls.binding;
    } else {
        return nil;
    }
}

+ (id)binding {
    return self;
}

+ (JSValue *)makeConstructor:(id)block inContext:(JSContext *)context {
    JSValue *fun = [context evaluateScript:@"(function () { return this.__construct.apply(this, arguments); });"];
    fun[@"prototype"][@"__construct"] = block;
    return fun;
}

+ (JSValue *)constructor {
    return [self makeConstructor:^{ return [self new]; } inContext:JSContext.currentContext];
}

@end
