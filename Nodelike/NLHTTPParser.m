//
//  NLHTTPParser.m
//  Nodelike
//
//  Created by Sam Rijs on 1/8/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLHTTPParser.h"

#import "http_parser.h"

const uint32_t kOnHeaders         = 0;
const uint32_t kOnHeadersComplete = 1;
const uint32_t kOnBody            = 2;
const uint32_t kOnMessageComplete = 3;

@implementation NLHTTPParser

+ (id)binding {

    JSContext *context = JSContext.currentContext;

    JSValue *parser = self.constructor;

    parser[@"REQUEST"]  = [NSNumber numberWithInt:HTTP_REQUEST];
    parser[@"RESPONSE"] = [NSNumber numberWithInt:HTTP_RESPONSE];

    parser[@"kOnHeaders"]         = [NSNumber numberWithInt:kOnHeaders];
    parser[@"kOnHeadersComplete"] = [NSNumber numberWithInt:kOnHeadersComplete];
    parser[@"kOnBody"]            = [NSNumber numberWithInt:kOnBody];
    parser[@"kOnMessageComplete"] = [NSNumber numberWithInt:kOnMessageComplete];

    JSValue *methods = [JSValue valueWithNewArrayInContext:context];
#define V(num, name, string)                                                  \
    [methods setValue:@#string atIndex:num];
    HTTP_METHOD_MAP(V)
#undef V

    parser[@"methods"] = methods;

    return @{@"HTTPParser": parser};

}

@end
