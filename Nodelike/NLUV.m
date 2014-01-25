//
//  NLUV.m
//  Nodelike
//
//  Created by Sam Rijs on 10/28/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLUV.h"

#import "uv.h"

@implementation NLUV

+ (id)binding {

    NSMutableDictionary *b = [NSMutableDictionary new];

    b[@"errname"] = ^(NSNumber *err) {
        return [NSString stringWithUTF8String:uv_err_name([err intValue])];
    };

#define V(name, _) [b setObject:[NSNumber numberWithInt:UV_ ## name] forKey:@"UV_" # name];
    UV_ERRNO_MAP(V)
#undef V

    return b;

}

@end
