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

#import "NLBuffer.h"

#import "http_parser.h"

const uint32_t kOnHeaders         = 0;
const uint32_t kOnHeadersComplete = 1;
const uint32_t kOnBody            = 2;
const uint32_t kOnMessageComplete = 3;

static const int num_fields_max = 32;

@implementation NLHTTPParser {
    http_parser parser_;
    NSMutableData *fields_[num_fields_max];  // header fields
    NSMutableData *values_[num_fields_max];  // header values
    NSMutableData *url_;
    NSMutableData *status_message_;
    int num_fields_;
    int num_values_;
    bool have_flushed_;
    bool got_exception_;
    JSValue *current_buffer_;
    size_t current_buffer_len_;
    char* current_buffer_data_;
    struct http_parser_settings settings;
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
    settings.on_message_begin = on_message_begin;
    settings.on_url = on_url;
    settings.on_status = on_status;
    settings.on_header_field = on_header_field;
    settings.on_header_value = on_header_value;
    settings.on_headers_complete = on_headers_complete;
    settings.on_body = on_body;
    settings.on_message_complete = on_message_complete;
    return self;
}

- (void)reinitialize:(NSNumber *)type {
    http_parser_init(&parser_, type.intValue);
    parser_.data    = (__bridge void *)(self);
    url_            = [NSMutableData new];
    status_message_ = [NSMutableData new];
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

- (JSValue *)execute:(JSValue *)buffer {
    
    JSContext *ctx = JSContext.currentContext;

    int   buffer_len  = [NLBuffer getLength:buffer];
    char *buffer_data = [NLBuffer getData:buffer ofSize:buffer_len];
    
    current_buffer_      = buffer;
    current_buffer_len_  = buffer_len;
    current_buffer_data_ = buffer_data;
    got_exception_       = false;
    
    size_t nparsed = http_parser_execute(&parser_, &settings, buffer_data, buffer_len);
    
    current_buffer_ = NULL;
    current_buffer_len_ = 0;
    current_buffer_data_ = NULL;
    
    if (got_exception_)
        return [JSValue valueWithUndefinedInContext:ctx];
    
    JSValue *nparsed_obj = [JSValue valueWithInt32:(int)nparsed inContext:ctx];
    
    if (!parser_.upgrade && nparsed != buffer_len) {
        JSValue *e = [JSValue valueWithNewErrorFromMessage:@"Parse Error" inContext:ctx];
        e[@"bytesParsed"] = nparsed_obj;
        e[@"code"]        = [NSString stringWithUTF8String:http_errno_name(HTTP_PARSER_ERRNO(&parser_))];
        return e;
    } else {
        return [JSValue valueWithObject:nparsed_obj inContext:ctx];
    }

}

- (JSValue *)finish {
    
    JSContext *ctx = JSContext.currentContext;

    got_exception_ = false;
    
    size_t nparsed = http_parser_execute(&parser_, &settings, NULL, 0);
    
    if (got_exception_)
        return [JSValue valueWithUndefinedInContext:ctx];
    
    if (nparsed) {
        JSValue *e = [JSValue valueWithNewErrorFromMessage:@"Parse Error" inContext:ctx];
        e[@"bytesParsed"] = @0;
        e[@"code"]        = [NSString stringWithUTF8String:http_errno_name(HTTP_PARSER_ERRNO(&parser_))];
        return e;
    } else {
        return [JSValue valueWithUndefinedInContext:ctx];
    }

}

- (JSValue *)headers {
    JSValue *headers = [JSValue valueWithNewArrayInContext:JSContext.currentContext];
    for (int i = 0; i < num_values_; ++i) {
        [headers setValue:[[NSString alloc] initWithData:fields_[i] encoding:NSASCIIStringEncoding] atIndex:2 * i];
        [headers setValue:[[NSString alloc] initWithData:values_[i] encoding:NSASCIIStringEncoding] atIndex:2 * i + 1];
    }
    return headers;
}

- (void)flush {
    
    JSContext   *ctx    = JSContext.currentContext;
    JSContextRef ctxRef = ctx.JSGlobalContextRef;
    
    JSValue   *obj    = JSContext.currentThis;
    JSValueRef objRef = obj.JSValueRef;
    JSValue   *cb     = [obj valueAtIndex:kOnHeaders];
    JSValueRef cbRef  = cb.JSValueRef;
    
    if (!JSValueIsObject(ctxRef, cbRef) || !JSObjectIsFunction(ctxRef, (JSObjectRef)cbRef))
        return;
    
    JSStringRef urlStrRef = JSStringCreateWithCFString((__bridge CFStringRef)url_);
    
    JSValueRef argv[2] = {
        self.headers.JSValueRef,
        JSValueMakeString(ctxRef, urlStrRef)
    };
    
    JSStringRelease(urlStrRef);

    JSValueRef r = JSObjectCallAsFunction(ctxRef, (JSObjectRef)cbRef, (JSObjectRef)objRef, 2, argv, NULL);
    
    if (!r)
        got_exception_ = true;
    
    [url_ setLength:0];
    have_flushed_ = true;
}

static int on_message_begin (http_parser* p) {
    NLHTTPParser *parser = (__bridge NLHTTPParser *)(p->data);
    parser->num_fields_ = parser->num_values_ = 0;
    [parser->url_ setLength:0];
    [parser->status_message_ setLength:0];
    return 0;
}

static int on_url (http_parser* p, const char* at, size_t length) {
    NLHTTPParser *parser = (__bridge NLHTTPParser *)(p->data);
    [parser->url_ appendBytes:at length:length];
    return 0;
}

static int on_status (http_parser* p, const char* at, size_t length) {
    NLHTTPParser *parser = (__bridge NLHTTPParser *)(p->data);
    [parser->status_message_ appendBytes:at length:length];
    return 0;
}

static int on_header_field (http_parser* p, const char* at, size_t length) {
    NLHTTPParser *parser = (__bridge NLHTTPParser *)(p->data);
    if (parser->num_fields_ == parser->num_values_) {
        parser->num_fields_++;
        if (parser->num_fields_ == num_fields_max) {
            [parser flush];
            parser->num_fields_ = 1;
            parser->num_values_ = 0;
        }
        parser->fields_[parser->num_fields_ - 1] = [NSMutableData new];
    }
    [parser->fields_[parser->num_fields_ - 1] appendBytes:at length:length];
    return 0;
}

static int on_header_value (http_parser* p, const char* at, size_t length) {
    NLHTTPParser *parser = (__bridge NLHTTPParser *)(p->data);
    if (parser->num_values_ != parser->num_fields_) {
        // start of new header value
        parser->num_values_++;
        parser->values_[parser->num_values_ - 1] = [NSMutableData new];
    }
    [parser->values_[parser->num_values_ - 1] appendBytes:at length:length];
    return 0;
}

static int on_headers_complete (http_parser* p) {
    NLHTTPParser *parser = (__bridge NLHTTPParser *)(p->data);
    
    JSContext   *ctx    = JSContext.currentContext;
    JSContextRef ctxRef = ctx.JSGlobalContextRef;
    
    JSValue   *obj    = JSContext.currentThis;
    JSValueRef objRef = obj.JSValueRef;
    JSValue   *cb     = [obj valueAtIndex:kOnHeadersComplete];
    JSValueRef cbRef  = cb.JSValueRef;
    
    if (!JSValueIsObject(ctxRef, cbRef) || !JSObjectIsFunction(ctxRef, (JSObjectRef)cbRef))
        return 0;
    
    JSValue *messageInfo = [JSValue valueWithNewObjectInContext:ctx];
    
    if (parser->have_flushed_) {
        // Slow case, flush remaining headers.
        [parser flush];
    } else {
        // Fast case, pass headers and URL to JS land.
        messageInfo[@"headers"] = parser.headers;
        if (parser->parser_.type == HTTP_REQUEST)
            messageInfo[@"url"] = [[NSString alloc] initWithData:parser->url_ encoding:NSASCIIStringEncoding];
    }
    parser->num_fields_ = parser->num_values_ = 0;
    
    // METHOD
    if (parser->parser_.type == HTTP_REQUEST) {
        messageInfo[@"method"] = [NSNumber numberWithUnsignedInt:parser->parser_.method];
    }
    
    // STATUS
    if (parser->parser_.type == HTTP_RESPONSE) {
        messageInfo[@"statusCode"] = [NSNumber numberWithUnsignedInt:parser->parser_.status_code];
        messageInfo[@"statusMessage"] = [[NSString alloc] initWithData:parser->status_message_ encoding:NSASCIIStringEncoding];
    }
    
    // VERSION
    messageInfo[@"versionMajor"] = [NSNumber numberWithInt:parser->parser_.http_major];
    messageInfo[@"versionMinor"] = [NSNumber numberWithInt:parser->parser_.http_minor];
    
    messageInfo[@"shouldKeepAlive"] = [NSNumber numberWithBool:http_should_keep_alive(&parser->parser_)];
    
    messageInfo[@"upgrade"] = [NSNumber numberWithBool:parser->parser_.upgrade];
    
    JSValueRef messageInfoRef = messageInfo.JSValueRef;
    
    JSValueRef head_response = JSObjectCallAsFunction(ctxRef, (JSObjectRef)cbRef, (JSObjectRef)objRef, 1, &messageInfoRef, NULL);

    if (!head_response) {
        parser->got_exception_ = true;
        return -1;
    }

    return JSValueToBoolean(ctxRef, head_response);

}

static int on_body (http_parser* p, const char* at, size_t length) {
    NLHTTPParser *parser = (__bridge NLHTTPParser *)(p->data);
    
    JSContext   *ctx    = JSContext.currentContext;
    JSContextRef ctxRef = ctx.JSGlobalContextRef;
    
    JSValue   *obj    = JSContext.currentThis;
    JSValueRef objRef = obj.JSValueRef;
    JSValue   *cb     = [obj valueAtIndex:kOnBody];
    JSValueRef cbRef  = cb.JSValueRef;
    
    if (!JSValueIsObject(ctxRef, cbRef) || !JSObjectIsFunction(ctxRef, (JSObjectRef)cbRef))
        return 0;
    
    JSValueRef argv[3] = {
        (parser->current_buffer_).JSValueRef,
        JSValueMakeNumber(ctxRef, at - parser->current_buffer_data_),
        JSValueMakeNumber(ctxRef, length)
    };
    
    JSValueRef r = JSObjectCallAsFunction(ctxRef, (JSObjectRef)cbRef, (JSObjectRef)objRef, 3, argv, NULL);
    
    if (!r) {
        parser->got_exception_ = true;
        return -1;
    }
    
    return 0;
}

static int on_message_complete (http_parser* p) {
    NLHTTPParser *parser = (__bridge NLHTTPParser *)(p->data);
    
    JSContext   *ctx    = JSContext.currentContext;
    JSContextRef ctxRef = ctx.JSGlobalContextRef;
    
    JSValue   *obj    = JSContext.currentThis;
    JSValueRef objRef = obj.JSValueRef;
    JSValue   *cb     = [obj valueAtIndex:kOnBody];
    JSValueRef cbRef  = cb.JSValueRef;
    
    if (parser->num_fields_)
        [parser flush];  // Flush trailing HTTP headers.
    
    if (!JSValueIsObject(ctxRef, cbRef) || !JSObjectIsFunction(ctxRef, (JSObjectRef)cbRef))
        return 0;
    
    JSValueRef r = JSObjectCallAsFunction(ctxRef, (JSObjectRef)cbRef, (JSObjectRef)objRef, 0, NULL, NULL);
    
    if (!r) {
        parser->got_exception_ = true;
        return -1;
    }
    
    return 0;
}


@end
