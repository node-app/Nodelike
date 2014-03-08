//
//  NLAsync.h
//  Nodelike
//
//  Created by Sam Rijs on 2/3/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBinding.h"

@interface NLAsync : NLBinding

@property (readonly) JSValue *object;
@property (readonly) JSContext *context;

- (instancetype)initInContext:(JSContext *)context;

+ (JSValue *)makeGlobalCallback:(JSValue *)func fromObject:(JSValue *)object withArguments:(NSArray *)args;
- (JSValue *)makeCallback:(JSValue *)func withArguments:(NSArray *)args;

- (void)makeCallbackFromMethod:(NSString *)method withArguments:(NSArray *)args;
- (void)makeCallbackFromIndex:(unsigned int)idx withArguments:(NSArray *)args;

+ (void)setupAsyncListener:(JSValue *)flagObj run:(JSValue *)run load:(JSValue *)load unload:(JSValue *)unload;
+ (bool)hasAsyncListener:(JSContext *)context;

+ (void)setupNextTick:(JSValue *)obj func:(JSValue *)func;

@end
