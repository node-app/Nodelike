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
#import <libkern/OSByteOrder.h>


typedef enum {
    NLEncodingAscii,
    NLEncodingBinary,
    NLEncodingUTF8,
    NLEncodingUCS2,
    NLEncodingVerbatim,
    NLEncodingHex,
    NLEncodingBase64,
} NLEncoding;

static NSData * base64Decode(NSString* str) {
    NSMutableString * plain = str.mutableCopy;
    // Replace URL-safe characters
    [plain replaceOccurrencesOfString:@"-"
                           withString:@"+"
                              options:0
                                range:NSMakeRange(0, plain.length)];
    [plain replaceOccurrencesOfString:@"_"
                           withString:@"/"
                              options:0
                                range:NSMakeRange(0, plain.length)];
    // Remove invalid characters
    NSCharacterSet * cs = [[NSCharacterSet characterSetWithCharactersInString: @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"] invertedSet];
    NSRange invalid = [plain rangeOfCharacterFromSet:cs];
    if (invalid.location != NSNotFound)
        plain = [[plain componentsSeparatedByCharactersInSet:cs]
                 componentsJoinedByString:@"" ].mutableCopy;
    // Remove padding
    while ([plain hasSuffix:@"="])
        [plain deleteCharactersInRange:NSMakeRange(plain.length-1,1)];
    // Pad length to multiple of 4
    NSString * pad;
    switch (plain.length % 4) {
        case 1:
            pad = @"===";
            break;
        case 2:
            pad = @"==";
            break;
        case 3:
            pad = @"=";
            break;
        default:
            pad = nil;
            break;
    }
    if (pad)
        [plain appendString:pad];
    return [[NSData alloc] initWithBase64EncodedString:plain
                                               options:0];
}

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
        case NLEncodingHex:
        case NLEncodingBase64:
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

static int utf8clen(const char * s, int rem) {
        int i = 0;
        while (rem--)
                if ((s[++i] & 0xC0) != 0x80)
                        break;
        return i;
}
 

static size_t writeString(NLEncoding enc, NSString *str, JSValue *target, int off, int len) {
    
    unichar *conv = NULL;
    const char *data = NULL;
    char *adata = NULL;
    
    switch (enc) {
    
        case NLEncodingBinary:
        case NLEncodingAscii:
        len  = MIN(len, (int)str.length);
        conv = malloc(len * sizeof(unichar));
        data = adata = malloc(len);
        [str getCharacters:conv];
        for (int i = 0; i < len; i++) {
            adata[i] = conv[i] % 256;
        }
        break;

        case NLEncodingHex:
        len = MIN(len, (int)str.length/2);
        conv = malloc(str.length * sizeof(unichar));
        data = adata = malloc(len);
        [str getCharacters:conv];
        for (int i = 0; i < len; i++) {
            char buf[3];
            buf[0] = conv[2*i+0]; buf[1] = conv[2*i+1]; buf[2] = 0;
            adata[i] = strtol(buf, 0, 16);
        }
        break;

        case NLEncodingBase64:
        {
            NSData * d = base64Decode(str);
            len  = MIN(len, (int)d.length);
            data = len? (char*)d.bytes : 0;
        }
        break;

        case NLEncodingUTF8:
        {
            int sblen = (int)[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            len = MIN(len, sblen);
            size_t sz = len;
            data = adata = malloc(sz+1);
            const char * src = str.UTF8String;
            int sofar = 0;
            int i;
            int slen = (int)str.length;
            for (i = 0; i < slen; i++) {
                int clen = utf8clen(src+sofar, sblen-sofar);
                if (sz-sofar >= clen) {
                    memcpy(adata+sofar, src+sofar, clen);
                    sofar += clen;
                } else
                    break;
            }
            len = sofar;
        }
        break;

        case NLEncodingVerbatim:
        {
            int blen = (int)[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            data = (char *)[str cStringUsingEncoding:NSUTF8StringEncoding];
            len  = MIN(len, blen);
        }
        break;
        
        case NLEncodingUCS2:
        data = (char *)[str cStringUsingEncoding:NSUTF16StringEncoding];
        len  = MIN(len, (int)[str lengthOfBytesUsingEncoding:NSUTF16StringEncoding]);
        len &= ~1;
        break;
        
        default:
        assert(0 && "unknown encoding");
        break;
        
    }
    
    size_t size = writeBuffer(enc, data, target, off, len);

    if (conv)
        free(conv);
    if (adata)
        free(adata);
    
    return size;

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

static const unsigned char hextab[] = "0123456789abcdef";

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

+ (JSValue *)writeLE:(const void *)data toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(int) len {
    
    unsigned obj_length = [target[@"length"] toUInt32];
    unsigned offset     = [off isUndefined] ?                   0 : [off toUInt32];
    if (offset > (obj_length - len)) {
            target.context.exception = [target.context evaluateScript:@"new RangeError('attempt to write outside buffer bounds');"]; 
            return target.context.exception;
    }

    return [JSValue valueWithUInt32: offset + (unsigned)writeBuffer(NLEncodingVerbatim, data, target, offset, MIN(obj_length - offset, len)) inContext:target.context];
    
}

+ (JSValue *)writeBE:(const void *)data toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(int) len {
	char bedata[8];
	switch (len) {
	case 4: *(uint32_t*)bedata = OSSwapInt32(*(uint32_t*)data); break;
	case 8: *(uint64_t*)bedata = OSSwapInt64(*(uint64_t*)data); break;
	default: assert(0);
	}
	return [self writeLE:bedata toBuffer: target atOffset:off withLength:len];
}

+ (JSValue *)readFPFromBuffer:(JSValue *)target atOffset:(unsigned)offset length:(unsigned)len big:(BOOL)big{
    char data[8];
    unsigned olen = [target[@"length"] toUInt32];
    if (offset > (olen - len)) {
            target.context.exception = [target.context evaluateScript:@"new RangeError('attempt to read outside buffer bounds');"]; 
            return target.context.exception;
    }
    sliceBuffer(data, target, offset, len);
    double d;
    switch (len) {
    case 4: 
	    if (big) *(int32_t*)data = OSSwapInt32(*(int32_t*)data);
	    d = *(float*)data; 
	    break;
    case 8: 
	    if (big) *(int64_t*)data = OSSwapInt64(*(int64_t*)data);
	    d = *(double*)data;
	    break;
    default:assert(0);
    }
    return [JSValue valueWithDouble: d inContext:target.context];
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

+ (NSString *)sliceUcs2:(JSValue *)buffer from:(NSNumber *)start_arg to:(NSNumber *)end_arg {
    int   start = start_arg.intValue, end = end_arg.intValue, len = end - start;
    char *data  = sliceBuffer(malloc(len), buffer, start, len);
    NSString *str = [[NSString alloc] initWithBytes:data length:len encoding:NSUTF16LittleEndianStringEncoding];
    free(data);
    return str;
}

+ (NSString *)sliceBase64:(JSValue *)buffer from:(NSNumber *)start_arg to:(NSNumber *)end_arg {
    int   start = start_arg.intValue, end = end_arg.intValue, len = end - start;
    char *data  = sliceBuffer(malloc(len), buffer, start, len);
    NSData * d = [NSData dataWithBytes:data length:len];
    NSString *str = [d base64EncodedStringWithOptions:0];
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
    const char * cstr = strVal.UTF8String;
    unsigned long valLen = strlen(cstr);
    
    JSValueRef intVal;

    for (int i = 0; i < len; i++) {
        intVal = JSValueMakeNumber(context, (unsigned char)cstr[i % valLen]);
        JSObjectSetPropertyAtIndex(context, buffer, i + start, intVal, nil);
    }

}

// base64DecodeSize shamelessly stolen from Node.js string_bytes.cc

static inline size_t base64DecodedSizeFast(size_t size) {
	size_t remainder = size % 4;

	size = (size / 4) * 3;
	if (remainder) {
		if (size == 0 && remainder == 1) {
			// special case: 1-byte input cannot be decoded
			size = 0;
		} else {
			// non-padded input, add 1 or 2 extra bytes
			size += 1 + (remainder == 3);
		}
	}

	return size;
}

static size_t base64DecodedSize(const char * src, size_t size) {
	if (size == 0)
		return 0;

	if (src[size - 1] == '=')
		size--;
	if (size > 0 && src[size - 1] == '=')
		size--;

	return base64DecodedSizeFast(size);
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

    proto[@"ucs2Slice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBuffer sliceUcs2:NLContext.currentThis from:start to:end];
    };
    
    proto[@"hexSlice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBuffer sliceHex:JSContext.currentThis from:start to:end];
    };

    proto[@"base64Slice"] = ^(NSNumber *start, NSNumber *end) {
        return [NLBuffer sliceBase64:JSContext.currentThis from:start to:end];
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

    proto[@"hexWrite"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBuffer writeString:string usingEncoding:NLEncodingHex toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };

    proto[@"base64Write"] = ^(NSString *string, JSValue *off, JSValue *len) {
        return [NLBuffer writeString:string usingEncoding:NLEncodingBase64 toBuffer:NLContext.currentThis atOffset:off withLength:len];
    };

    proto[@"writeFloatLE"] = ^(float val, JSValue * off) {
            return [NLBuffer writeLE:&val
                          toBuffer:NLContext.currentThis 
                          atOffset:off 
                          withLength:sizeof(val)];
    };

    proto[@"writeFloatBE"] = ^(float val, JSValue * off) {
            return [NLBuffer writeBE:&val
                          toBuffer:NLContext.currentThis 
                          atOffset:off 
                          withLength:sizeof(val)];
    };

    proto[@"writeDoubleLE"] = ^(double val, JSValue * off) {
            return [NLBuffer writeLE:&val
                          toBuffer:NLContext.currentThis 
                          atOffset:off 
                          withLength:sizeof(val)];
    };

    proto[@"writeDoubleBE"] = ^(double val, JSValue * off) {
            return [NLBuffer writeBE:&val
                          toBuffer:NLContext.currentThis 
                          atOffset:off 
                          withLength:sizeof(val)];
    };

    proto[@"readFloatLE"] = ^(unsigned off) {
            return [NLBuffer readFPFromBuffer:NLContext.currentThis
                                     atOffset:off
                                       length:sizeof(float)
					big:NO];
    };

    proto[@"readFloatBE"] = ^(unsigned off) {
            return [NLBuffer readFPFromBuffer:NLContext.currentThis
				   atOffset:off
				     length:sizeof(float)
					big:YES];
    };

    proto[@"readDoubleLE"] = ^(unsigned off) {
            return [NLBuffer readFPFromBuffer:NLContext.currentThis
				   atOffset:off
				     length:sizeof(double)
					big:NO];
    };

    proto[@"readDoubleBE"] = ^(unsigned off) {
            return [NLBuffer readFPFromBuffer:NLContext.currentThis
				   atOffset:off
				     length:sizeof(double)
					big:YES];
    };
    
    internal[@"byteLength"] = ^(NSString *string, NSString * encoding) {
        if ([encoding isEqualToString:@"base64"])
		return (NSUInteger)base64DecodedSize(string.UTF8String, string.length);
        return [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    };
    
}

@end
