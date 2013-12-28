//
//  NLBindingBuffer.m
//  NodelikeDemo
//
//  Created by Sam Rijs on 10/19/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLBindingBuffer.h"

static JSValue *constructor = nil;

static size_t writeBuffer(const char *data, JSValue *target, int off, int len) {
    JSContextRef context = target.context.JSGlobalContextRef;
    JSObjectRef  buffer  = (JSObjectRef)target.JSValueRef;
    for (int i = 0; i < len; i++) {
        JSObjectSetPropertyAtIndex(context, buffer, i + off, JSValueMakeNumber(context, data[i]), nil);
    }
    return len;
}

static char *sliceBuffer(char *data, JSValue *target, int off, int len) {
    JSContextRef contextRef = target.context.JSGlobalContextRef;
    JSObjectRef  bufferRef  = (JSObjectRef)target.JSValueRef;
    for (int i = 0; i < len; i++) {
        JSValueRef prop = JSObjectGetPropertyAtIndex(contextRef, bufferRef, i + off, nil);
        data[i] = JSValueToNumber(contextRef, prop, nil);
    }
    return data;
}

@implementation NLBindingBuffer

+ (id)binding {
    return @{@"setupBufferJS": ^(JSValue *target, JSValue *internal) {
        [self setupBufferJS:target internal:internal];}};
}

+ (JSValue *)constructor {
    return constructor;
}

+ (JSValue *)useData:(const char *)data ofLength:(int)len {
    JSValue *buffer = [constructor constructWithArguments:@[[NSNumber numberWithInt:len]]];
    writeBuffer(data, buffer, 0, len);
    return buffer;
}

+ (NSNumber *)writeString:(longlived NSString *)str toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len {
    return [NLBindingBuffer write:str.UTF8String toBuffer:target atOffset:off withLength:len];
}

+ (NSNumber *)write:(const char *)data toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len {
    
    int obj_length = [target[@"length"] toInt32],
        offset     = [off isUndefined] ?                   0 : [off toUInt32],
        max_length = [len isUndefined] ? obj_length - offset : [len toUInt32];
    
    return [NSNumber numberWithUnsignedInteger:writeBuffer(data, target, offset, MIN(obj_length - offset, max_length))];
    
}

+ (int)getLength:(JSValue *)buffer {
    return [buffer[@"length"] toInt32];
}

+ (char *)getData:(JSValue *)buffer ofSize:(int)size {
    return sliceBuffer(malloc(size), buffer, 0, size);
}

+ (NSString *)slice:(JSValue *)buffer from:(NSNumber *)start_arg to:(NSNumber *)end_arg {
    int   start = start_arg.intValue, end = end_arg.intValue, len = end - start;
    char *data  = sliceBuffer(malloc(len + 1), buffer, start, len);
    data[len] = '\0';
    NSString *str = [NSString stringWithUTF8String:data];
    free(data);
    return str;
}

+ (void)setupBufferJS:(JSValue *)target internal:(JSValue *)internal {

    constructor = target;

    JSValue *proto = target[@"prototype"];
    
    proto[@"asciiSlice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBindingBuffer slice:NLContext.currentThis from:start to:end];
    };
    
    proto[@"binarySlice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBindingBuffer slice:NLContext.currentThis from:start to:end];
    };
    
    proto[@"utf8Slice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBindingBuffer slice:NLContext.currentThis from:start to:end];
    };
    
    proto[@"asciiWrite"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBindingBuffer writeString:string toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };
    
    proto[@"binaryWrite"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBindingBuffer writeString:string toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };
    
    proto[@"utf8Write"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBindingBuffer writeString:string toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };
    
    internal[@"byteLength"] = ^(NSString *string) {
        return [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    };
    
}

@end
