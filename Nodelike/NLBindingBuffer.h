//
//  NLBindingBuffer.h
//  NodelikeDemo
//
//  Created by Sam Rijs on 10/19/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLBinding.h"

@interface NLBindingBuffer : NLBinding

+ (JSValue *)constructor;

+ (JSValue *)useData:(const char *)data ofLength:(int)len;

+ (int)getLength:(JSValue *)buffer;
+ (char *)getData:(JSValue *)buffer ofSize:(int)size;

+ (NSNumber *)writeString:(NSString *)str toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len;

+ (NSNumber *)write:(const char *)data toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len;

@end
