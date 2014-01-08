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

@implementation NLHTTPParser {
    http_parser parser_;
    NSString *fields_[32];  // header fields
    NSString *values_[32];  // header values
    NSString *url_;
    NSString *status_message_;
    int num_fields_;
    int num_values_;
    bool have_flushed_;
    bool got_exception_;
    JSValue *current_buffer_;
    size_t current_buffer_len_;
    char* current_buffer_data_;
    const struct http_parser_settings settings;
}

+ (id)binding {

    JSContext *context = JSContext.currentContext;

    JSValue *parser = [NLBinding makeConstructor:^(NSNumber *type) {
        NLHTTPParser *p = [[NLHTTPParser alloc] init];
        [p reinitialize:type];
        return p;
    }  inContext:context];

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

- (instancetype)init {
    self = [super init];
    current_buffer_len_  = 0;
    current_buffer_data_ = NULL;
    return self;
}

- (void)reinitialize:(NSNumber *)type {
    http_parser_init(&parser_, type.intValue);
    url_            = @"";
    status_message_ = @"";
    num_fields_     = 0;
    num_values_     = 0;
    have_flushed_   = false;
    got_exception_  = false;
}

- (void)pause {
    http_parser_pause(&parser_, true);
}

- (void)resume {
    http_parser_pause(&parser_, false);
}

@end
