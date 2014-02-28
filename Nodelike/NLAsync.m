//
//  NLAsync.m
//  Nodelike
//
//  Created by Sam Rijs on 2/3/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLAsync.h"

@implementation NLAsync

- (instancetype)initInContext:(JSContext *)context {
    self = [super init];
    _context = context;
    return self;
}

- (JSValue *)object {
    return [JSValue valueWithObject:self inContext:self.context];
}

- (void)makeCallbackFromMethod:(NSString *)method withArguments:(NSArray *)args {
    [self.object invokeMethod:method withArguments:args];
}

- (void)makeCallbackFromIndex:(unsigned int)idx withArguments:(NSArray *)args {
    JSValue     *wrap       = self.object;
    JSObjectRef  wrapRef    = (JSObjectRef)(wrap.JSValueRef);
    JSContext   *context    = self.context;
    JSContextRef contextRef = context.JSGlobalContextRef;
    JSValueRef   callback   = JSObjectGetPropertyAtIndex(contextRef, wrapRef, idx, nil);
    if (callback && JSValueIsObject(contextRef, callback) && JSObjectIsFunction(contextRef, (JSObjectRef)callback)) {
        NSUInteger  argc  = args.count;
        JSValueRef *argsv = calloc(argc, sizeof(JSValueRef));
        for (int i = 0; i < argc; i++) {
            argsv[i] = [JSValue valueWithObject:args[i] inContext:context].JSValueRef;
        }
        JSObjectCallAsFunction(contextRef, (JSObjectRef)callback, wrapRef, argc, argsv, nil);
    }
}

@end
