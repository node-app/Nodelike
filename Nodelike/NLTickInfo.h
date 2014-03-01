//
//  NLTickInfo.h
//  Nodelike
//
//  Created by Sam Rijs on 3/1/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface NLTickInfo : NSObject

+ (void)initObject:(JSValue *)object;

+ (void)setObject:(JSValue *)object inContext:(JSContext *)context;
+ (JSValue *)getObjectInContext:(JSContext *)context;

+ (void)setCallback:(JSValue *)object inContext:(JSContext *)context;
+ (JSValue *)getCallbackInContext:(JSContext *)context;

+ (int)fieldsCount:(JSValue *)object;
+ (bool)inTick:(JSValue *)object;
+ (uint32_t)index:(JSValue *)object;
+ (bool)lastThrew:(JSValue *)object;
+ (uint32_t)length:(JSValue *)object;

+ (void)setInTick:(JSValue *)object on:(bool)on;
+ (void)setIndex:(JSValue *)object index:(uint32_t)index;
+ (void)setLastThrew:(JSValue *)object on:(bool)on;

@end
