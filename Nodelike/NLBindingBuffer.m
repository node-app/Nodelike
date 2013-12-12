//
//  NLBindingBuffer.m
//  NodelikeDemo
//
//  Created by Sam Rijs on 10/19/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLBindingBuffer.h"

static JSValue *constructor;

size_t writeBuffer(const char *data, JSValue *buffer, size_t off, size_t len) {
    for (int i = 0; i < len; i++) {
        JSValue *val = [JSValue valueWithInt32:data[i] inContext:buffer.context];
        [buffer setValue:val atIndex:i + off];
    }
    return len;
}

@implementation NLBindingBuffer

+ (id)binding {
    return @{@"setupBufferJS": ^(JSValue *target, JSValue *internal) {
        [self setupBufferJS:target internal:internal];}};
}

+ (JSValue *)constructor {
    return constructor;
}

+ (JSValue *)useData:(const char *)data ofLength:(size_t)len {
    JSValue *buffer = [[self constructor] callWithArguments:@[[NSNumber numberWithLong:len]]];
    writeBuffer(data, buffer, 0, len);
    return buffer;
}

+ (NSNumber *)writeString:(longlived NSString *)str toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len {
    return [NLBindingBuffer write:[str UTF8String] toBuffer:target atOffset:off withLength:len];
}

+ (NSNumber *)write:(const char *)data toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len {
    
    size_t obj_length = [target[@"length"] toUInt32];
    
    size_t offset;
    size_t max_length;
    
    offset     = [off isUndefined] ?                   0 : [off toUInt32];
    max_length = [len isUndefined] ? obj_length - offset : [len toUInt32];
    
    max_length = MIN(obj_length - offset, max_length);
    
    return [NSNumber numberWithUnsignedInteger:writeBuffer(data, target, offset, max_length)];
    
}

+ (NSString *)slice:(JSValue *)buffer from:(NSNumber *)start_arg to:(NSNumber *)end_arg inContext:(NLContext *)ctx {
    size_t start = [start_arg intValue], end = [end_arg intValue], len = end - start;
    char *data = malloc(len + 1);
    for (int i = 0; i < len; i++) {
        data[i] = [[buffer valueAtIndex:i + start] toInt32];
    }
    data[len] = '\0';
    NSString *str = [NSString stringWithUTF8String:data];
    free(data);
    return str;
}

+ (void)setupBufferJS:(JSValue *)target internal:(JSValue *)internal {

    constructor = target;

    JSValue *proto = target[@"prototype"];
    
    proto[@"asciiSlice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBindingBuffer slice:[NLContext currentThis] from:start to:end inContext:[NLContext currentContext]];
    };
    
    proto[@"binarySlice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBindingBuffer slice:[NLContext currentThis] from:start to:end inContext:[NLContext currentContext]];
    };
    
    proto[@"utf8Slice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBindingBuffer slice:[NLContext currentThis] from:start to:end inContext:[NLContext currentContext]];
    };
    
    proto[@"asciiWrite"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBindingBuffer writeString:string toBuffer:[NLContext currentThis] atOffset:off withLength:len];
    };
    
    proto[@"binaryWrite"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBindingBuffer writeString:string toBuffer:[NLContext currentThis] atOffset:off withLength:len];
    };
    
    proto[@"utf8Write"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBindingBuffer writeString:string toBuffer:[NLContext currentThis] atOffset:off withLength:len];
    };
    
    internal[@"byteLength"] = ^(NSString *string) {
        return [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    };
    
}

@end
