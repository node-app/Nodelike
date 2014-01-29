//
//  NLNatives.m
//  Nodelike
//
//  Created by Sam Rijs on 1/25/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLNatives.h"

@implementation NLNatives

+ (NSBundle *)bundle {
    NSBundle *bundle     = [NSBundle bundleForClass:self.class];
    NSString *bundlePath = [bundle pathForResource:@"Nodelike" ofType:@"bundle"];
    if (bundlePath) {
        return [NSBundle bundleWithPath:bundlePath];
    } else {
        return bundle;
    }
}

+ (NSArray *)modules {
    NSArray *files = [NSBundle pathsForResourcesOfType:@"js" inDirectory:self.bundle.bundlePath];
    NSMutableArray *modules = [NSMutableArray new];
    for (int i = 0; i < files.count; i++) {
        NSURL    *url  = files[i];
        NSString *name = [url.lastPathComponent substringToIndex:url.lastPathComponent.length - url.pathExtension.length - 1];
        [modules addObject:name];
    }
    return modules;
}

+ (NSString *)source:(NSString *)module {
    NSString *path    = [self.bundle pathForResource:module ofType:@"js"];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    return content;
}

+ (id)binding {
    NSArray *modules = [self modules];
    JSValue *sources = [JSValue valueWithNewObjectInContext:JSContext.currentContext];
    for (int i = 0; i < modules.count; i++) {
        NSString *name = modules[i];
        [sources defineProperty:name
                     descriptor:@{JSPropertyDescriptorGetKey: ^{ return [NLNatives source:name]; }}];
    }
    return sources;
}

@end
