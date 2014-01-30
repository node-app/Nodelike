//
//  NLBuffer.h
//  Nodelike
//
//  Created by Sam Rijs on 10/19/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBinding.h"

@interface NLBuffer : NLBinding

+ (JSValue *)constructorInContext:(JSContext *)context;

+ (JSValue *)useData:(const char *)data ofLength:(int)len inContext:(JSContext *)ctx;

+ (int)getLength:(JSValue *)buffer;
+ (char *)getData:(JSValue *)buffer ofSize:(int)size;

+ (NSNumber *)writeString:(NSString *)str toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len;

+ (NSNumber *)write:(const char *)data toBuffer:(JSValue *)target atOffset:(JSValue *)off withLength:(JSValue *)len;

@end
