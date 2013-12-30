//
//  NLBinding.h
//  Nodelike
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

#import "uv.h"

#import "NLContext.h"

// In order to guarantee that the C string derived from an
// NSString -UTF8String method call survives until libuv
// gets a chance to copy it, it is annotated with the following
// attribute, which guarantees that the object will be alive until
// the end of the scope.
#define longlived __attribute((objc_precise_lifetime))

@interface NLBinding : NSObject

+ (id)bindingForIdentifier:(NSString *)identifier;

+ (id)binding;

+ (JSValue *)makeConstructor:(id)block inContext:(JSContext *)context;
+ (JSValue *)constructor;

@end
