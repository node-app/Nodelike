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

#import "NLBindingFilesystem.h"
#import "NLBindingConstants.h"
#import "NLBindingSmalloc.h"
#import "NLBindingBuffer.h"
#import "NLCaresWrap.h"
#import "NLBindingUv.h"
#import "NLTimer.h"
#import "NLTCP.h"
#import "NLUDP.h"
#import "NLProcess.h"
#import "NLHTTPParser.h"

@implementation NLBinding

+ (NSCache *)bindingCache {
    static NSCache *cache = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        cache = [NSCache new];
    });
    return cache;
}

+ (NSDictionary *)bindings {
    static NSDictionary *bindings = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        bindings = @{@"fs":           NLBindingFilesystem.class,
                     @"constants":    NLBindingConstants.class,
                     @"smalloc":      NLBindingSmalloc.class,
                     @"buffer":       NLBindingBuffer.class,
                     @"timer_wrap":   NLTimer.class,
                     @"cares_wrap":   NLCaresWrap.class,
                     @"tcp_wrap":     NLTCP.class,
                     @"udp_wrap":     NLUDP.class,
                     @"uv":           NLBindingUv.class,
                     @"process_wrap": NLProcess.class,
                     @"http_parser":  NLHTTPParser.class};
    });
    return bindings;
}

+ (id)bindingForIdentifier:(NSString *)identifier {
    NSCache *cache = NLBinding.bindingCache;
    id binding = [cache objectForKey:identifier];
    if (binding != nil) {
        return binding;
    }
    Class cls = NLBinding.bindings[identifier];
    if (cls) {
        binding = cls.binding;
        [cache setObject:binding forKey:identifier];
        return binding;
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
