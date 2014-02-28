//
//  NLBuffer.m
//  Nodelike
//
//  Created by Sam Rijs on 10/19/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBuffer.h"

#import "NSObject+Nodelike.h"

typedef enum {
    NLEncodingAscii,
    NLEncodingBinary,
    NLEncodingUTF8,
    NLEncodingUCS2,
    NLEncodingVerbatim
} NLEncoding;

static size_t writeBuffer(NLEncoding enc, const char *data, JSValue *target, int off, int len) {
    
    JSContextRef context = target.context.JSGlobalContextRef;
    JSObjectRef  buffer  = JSValueToObject(context, target.JSValueRef, nil);
    
    switch (enc) {
        
        case NLEncodingUTF8:
        case NLEncodingUCS2:
        case NLEncodingVerbatim:
        for (int i = 0; i < len; i++) {
            JSObjectSetPropertyAtIndex(context, buffer, i + off, JSValueMakeNumber(context, (unsigned char)data[i]), nil);
        }
        break;
        
        case NLEncodingAscii:
        case NLEncodingBinary:
        for (int i = 0; i < len; i++) {
            JSObjectSetPropertyAtIndex(context, buffer, i + off, JSValueMakeNumber(context, (unsigned char)data[i] % 256), nil);
        }
        break;
        
        default:
        assert(0 && "unknown encoding");
        break;
        
    }
    
    return len;
    
}

static size_t writeString(NLEncoding enc, NSString *str, JSValue *target, int off, int len) {
    
    unichar *conv;
    char    *data;
    
    switch (enc) {
     
        case NLEncodingBinary:
        case NLEncodingAscii:
        len  = MIN(len, (int)str.length);
        conv = malloc(len * sizeof(unichar));
        data = malloc(len);
        [str getCharacters:conv];
        for (int i = 0; i < len; i++) {
            data[i] = conv[i] % 256;
        }
        break;
        
        case NLEncodingUTF8:
        case NLEncodingVerbatim:
        data = (char *)[str cStringUsingEncoding:NSUTF8StringEncoding];
        len  = MIN(len, (int)[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        break;
        
        case NLEncodingUCS2:
        data = (char *)[str cStringUsingEncoding:NSUTF16StringEncoding];
        len  = MIN(len, (int)[str lengthOfBytesUsingEncoding:NSUTF16StringEncoding]);
        break;
        
        default:
        assert(0 && "unknown encoding");
        break;
        
    }
    
    return writeBuffer(enc, data, target, off, len);

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

static JSChar *sliceBufferAscii(JSChar *data, JSValue *target, int off, int len) {
    JSContextRef contextRef = target.context.JSGlobalContextRef;
    JSObjectRef  bufferRef  = (JSObjectRef)target.JSValueRef;
    for (int i = 0; i < len; i++) {
        JSValueRef prop = JSObjectGetPropertyAtIndex(contextRef, bufferRef, i + off, nil);
        data[i] = (unsigned char)JSValueToNumber(contextRef, prop, nil) % 128;
    }
    return data;
}

static JSChar *sliceBufferBinary(JSChar *data, JSValue *target, int off, int len) {
    JSContextRef contextRef = target.context.JSGlobalContextRef;
    JSObjectRef  bufferRef  = (JSObjectRef)target.JSValueRef;
    for (int i = 0; i < len; i++) {
        JSValueRef prop = JSObjectGetPropertyAtIndex(contextRef, bufferRef, i + off, nil);
        data[i] = (unsigned char)JSValueToNumber(contextRef, prop, nil) % 256;
    }
    return data;
}

static unsigned char hextab[] = "0123456789abcdef";

static JSChar *sliceBufferHex(JSChar *data, JSValue *target, int off, int len) {
    JSContextRef contextRef = target.context.JSGlobalContextRef;
    JSObjectRef  bufferRef  = (JSObjectRef)target.JSValueRef;
    for (int i = 0; i < len; i++) {
        JSValueRef prop = JSObjectGetPropertyAtIndex(contextRef, bufferRef, i + off, nil);
        unsigned char val = (unsigned char)JSValueToNumber(contextRef, prop, nil) % 256;
        data[i * 2 + 0] = hextab[(val >> 4) & 0x0f];
        data[i * 2 + 1] = hextab[(val >> 0) & 0x0f];
    }
    return data;
}

@implementation NLBuffer

+ (id)binding {
    return @{@"setupBufferJS": ^(JSValue *target, JSValue *internal) {
                [self setupBufferJS:target internal:internal]; },
             @"SlowBuffer": self.constructor};
}

+ (JSValue *)constructorInContext:(JSContext *)ctx {
    assert(ctx != nil);
    return [ctx nodelikeGet:&env_buffer_constructor];
}

+ (JSValue *)useData:(const char *)data ofLength:(int)len inContext:(JSContext *)ctx {
    JSValue *buffer = [[self constructorInContext:ctx] constructWithArguments:@[[NSNumber numberWithInt:len]]];
    writeBuffer(NLEncodingVerbatim, data, buffer, 0, len);
    return buffer;
}

+ (NSNumber *)writeString:(longlived NSString *)str usingEncoding:(NLEncoding)enc toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len {
    
    int obj_length = [target[@"length"] toInt32],
    offset     = [off isUndefined] ?                   0 : [off toUInt32],
    max_length = [len isUndefined] ? obj_length - offset : [len toUInt32];
    
    return [NSNumber numberWithUnsignedInteger:writeString(enc, str, target, offset, MIN(obj_length - offset, max_length))];
    
}

+ (NSNumber *)writeString:(longlived NSString *)str toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len {
    return [NLBuffer writeString:str usingEncoding:NLEncodingVerbatim toBuffer:target atOffset:off withLength:len];
}

+ (NSNumber *)write:(const char *)data toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len {
    
    int obj_length = [target[@"length"] toInt32],
        offset     = [off isUndefined] ?                   0 : [off toUInt32],
        max_length = [len isUndefined] ? obj_length - offset : [len toUInt32];
    
    return [NSNumber numberWithUnsignedInteger:writeBuffer(NLEncodingVerbatim, data, target, offset, MIN(obj_length - offset, max_length))];
    
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

+ (JSValue *)sliceAscii:(JSValue *)buffer from:(NSNumber *)start_arg to:(NSNumber *)end_arg {
    int   start = start_arg.intValue, end = end_arg.intValue, len = end - start;
    JSChar *data  = sliceBufferAscii(calloc(len, sizeof(JSChar)), buffer, start, len);
    JSContextRef c = buffer.context.JSGlobalContextRef;
    JSStringRef  s = JSStringCreateWithCharacters(data, len);
    free(data);
    return [JSValue valueWithJSValueRef:JSValueMakeString(c, s) inContext:buffer.context];
}

+ (JSValue *)sliceBinary:(JSValue *)buffer from:(NSNumber *)start_arg to:(NSNumber *)end_arg {
    int   start = start_arg.intValue, end = end_arg.intValue, len = end - start;
    JSChar *data  = sliceBufferBinary(calloc(len, sizeof(JSChar)), buffer, start, len);
    JSContextRef c = buffer.context.JSGlobalContextRef;
    JSStringRef  s = JSStringCreateWithCharacters(data, len);
    free(data);
    return [JSValue valueWithJSValueRef:JSValueMakeString(c, s) inContext:buffer.context];
}

+ (JSValue *)sliceHex:(JSValue *)buffer from:(NSNumber *)start_arg to:(NSNumber *)end_arg {
    int   start = start_arg.intValue, end = end_arg.intValue, len = end - start;
    JSChar *data  = sliceBufferHex(calloc(len * 2, sizeof(JSChar)), buffer, start, len);
    JSContextRef c = buffer.context.JSGlobalContextRef;
    JSStringRef  s = JSStringCreateWithCharacters(data, len * 2);
    free(data);
    return [JSValue valueWithJSValueRef:JSValueMakeString(c, s) inContext:buffer.context];
}

+ (NSNumber *)copy:(JSValue *)source
            target:(JSValue *)target targetStart:(JSValue *)targetStartArg
       sourceStart:(JSValue *)sourceStartArg sourceEnd:(JSValue *)sourceEndArg {

    int targetLength = [NLBuffer getLength:target],
        sourceLength = [NLBuffer getLength:source],
        targetStart  = targetStartArg.isUndefined ? 0 : targetStartArg.toInt32,
        sourceStart  = sourceStartArg.isUndefined ? 0 : sourceStartArg.toInt32,
        sourceEnd    = sourceEndArg.isUndefined   ? sourceLength : sourceEndArg.toInt32;
    
    if (targetStart >= targetLength || sourceStart >= sourceEnd)
        return [NSNumber numberWithInt:0];
    
    if (sourceEnd - sourceStart > targetLength - targetStart)
        sourceEnd = sourceStart + targetLength - targetStart;
    
    int toCopy = MIN(MIN(sourceEnd - sourceStart, targetLength - targetStart), sourceLength - sourceStart);
    
    JSContextRef context      = target.context.JSGlobalContextRef;
    JSObjectRef  sourceBuffer = JSValueToObject(context, source.JSValueRef, nil),
                 targetBuffer = JSValueToObject(context, target.JSValueRef, nil);
    JSValueRef   value;
    
    for (int i = 0; i < toCopy; i++) {
        value = JSObjectGetPropertyAtIndex(context, sourceBuffer, i + sourceStart, nil);
        JSObjectSetPropertyAtIndex(context, targetBuffer, i + targetStart, value, nil);
    }
    
    return [NSNumber numberWithInt:toCopy];
    
}

+ (void)fill:(JSValue *)target with:(JSValue *)value from:(JSValue *)start_arg to:(JSValue *)end_arg {

    int start = start_arg.isUndefined ? 0 : start_arg.toInt32,
        end   = end_arg.isUndefined   ? [self getLength:target] : end_arg.toInt32,
        len   = end - start;

    JSContextRef context = target.context.JSGlobalContextRef;
    JSObjectRef  buffer  = JSValueToObject(context, target.JSValueRef, nil);
    
    if (value.isNumber) {
        JSValueRef intVal = JSValueMakeNumber(context, value.toInt32 % 256);
        for (int i = start; i < end; i++) {
            JSObjectSetPropertyAtIndex(context, buffer, i, intVal, nil);
        }
        return;
    }
    
    NSString     *strVal = value.toString;
    unsigned long valLen = strVal.length;
    
    JSValueRef intVal;

    for (int i = 0; i < len; i++) {
        intVal = JSValueMakeNumber(context, (unsigned char)[strVal characterAtIndex:i % valLen]);
        JSObjectSetPropertyAtIndex(context, buffer, i + start, intVal, nil);
    }

}

+ (void)setupBufferJS:(JSValue *)target internal:(JSValue *)internal {

    [JSContext.currentContext nodelikeSet:&env_buffer_constructor toValue:target];

    JSValue *proto = target[@"prototype"];
    
    proto[@"fill"] = ^(JSValue *value, JSValue *start, JSValue *end) {
        return [NLBuffer fill:JSContext.currentThis with:value from:start to:end];
    };
    
    proto[@"copy"] = ^(JSValue *target, JSValue *targetStart, JSValue *sourceStart, JSValue *sourceEnd) {
        return [NLBuffer copy:JSContext.currentThis target:target targetStart:targetStart sourceStart:sourceStart sourceEnd:sourceEnd];
    };
    
    proto[@"asciiSlice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBuffer sliceAscii:NLContext.currentThis from:start to:end];
    };
    
    proto[@"binarySlice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBuffer sliceBinary:NLContext.currentThis from:start to:end];
    };
    
    proto[@"utf8Slice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBuffer slice:NLContext.currentThis from:start to:end];
    };
    
    proto[@"hexSlice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBuffer sliceHex:JSContext.currentThis from:start to:end];
    };
    
    proto[@"asciiWrite"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBuffer writeString:string usingEncoding:NLEncodingAscii toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };
    
    proto[@"binaryWrite"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBuffer writeString:string usingEncoding:NLEncodingBinary toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };
    
    proto[@"utf8Write"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBuffer writeString:string usingEncoding:NLEncodingUTF8 toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };
    
    proto[@"ucs2Write"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBuffer writeString:string usingEncoding:NLEncodingUCS2 toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };
    
    internal[@"byteLength"] = ^(NSString *string) {
        return [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    };
    
}

@end
