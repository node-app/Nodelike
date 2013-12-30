//
//  NLCaresWrap.m
//  Nodelike
//
//  Created by Sam Rijs on 10/21/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLCaresWrap.h"

@implementation NLCaresWrap

+ (NSNumber *)isIP:(NSString *)ip {
    struct in6_addr address_buffer;
    int rc = 0;
    if (uv_inet_pton(AF_INET, [ip UTF8String], &address_buffer) == 0)
        rc = 4;
    else if (uv_inet_pton(AF_INET6, [ip UTF8String], &address_buffer) == 0)
        rc = 6;
    return [NSNumber numberWithInt:rc];
}

@end
