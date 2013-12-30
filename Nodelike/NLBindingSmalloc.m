//
//  NLBindingSmalloc.m
//  Nodelike
//
//  Created by Sam Rijs on 10/19/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBindingSmalloc.h"

@implementation NLBindingSmalloc

+ (id)binding {
    return @{@"alloc":     ^(JSValue *target, NSNumber *size) { return target; },
             @"sliceOnto": ^(JSValue *s, JSValue *d, NSNumber *a, NSNumber *b) { return s; },
             @"kMaxLength": [NSNumber numberWithInt:INT_MAX]};
}

@end
