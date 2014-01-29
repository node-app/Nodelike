//
//  NLNatives.h
//  Nodelike
//
//  Created by Sam Rijs on 1/25/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBinding.h"

@interface NLNatives : NLBinding

+ (NSBundle *)bundle;
+ (NSArray *)modules;
+ (NSString *)source:(NSString *)module;

@end
