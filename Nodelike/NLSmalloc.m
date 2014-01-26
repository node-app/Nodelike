//
//  NLSmalloc.m
//  Nodelike
//
//  Created by Sam Rijs on 10/19/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLSmalloc.h"

@implementation NLSmalloc

+ (id)binding {
    return @{@"kMaxLength": [NSNumber numberWithInt:INT_MAX],
             @"alloc": ^(JSValue *t, NSNumber *s) { return t; },
             @"sliceOnto": ^(JSValue *s, JSValue *d, NSNumber *a, NSNumber *b) {
                 return sliceOnto(s, d, a.intValue, b.intValue);
             }};
}

static JSValue *sliceOnto(JSValue *src, JSValue *dst, int start, int end) {
    int length = end - start;
    JSContextRef context = src.context.JSGlobalContextRef;
    JSObjectRef  srcRef  = JSValueToObject(context, src.JSValueRef, nil);
    JSObjectRef  dstRef  = JSValueToObject(context, dst.JSValueRef, nil);
    for (int i = 0; i < length; i++) {
        JSObjectSetPropertyAtIndex(context, dstRef, i, JSObjectGetPropertyAtIndex(context, srcRef, i + start, NULL), NULL);
    }
    return src;
}

@end
