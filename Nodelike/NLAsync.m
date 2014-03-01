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

#import "NSObject+Nodelike.h"

#import "NLTickInfo.h"

@implementation NLAsync

- (instancetype)initInContext:(JSContext *)context {
    self = [super init];
    _context = context;
    return self;
}

- (JSValue *)object {
    return [JSValue valueWithObject:self inContext:self.context];
}

+ (void)performTickCallbackInContext:(JSContext *)context {
    JSValue *tickInfo = [NLTickInfo getObjectInContext:context];
    
    if ([NLTickInfo inTick:tickInfo]) {
        return;
    }
    
    if ([NLTickInfo length:tickInfo] == 0) {
        [NLTickInfo setIndex:tickInfo index:0];
        return;
    }
    
    [NLTickInfo setInTick:tickInfo on:YES];
    
    [NLAsync makeCallback:[NLTickInfo getCallbackInContext:context]
               fromObject:[context.virtualMachine nodelikeGet:&env_process_object]
            withArguments:@[]];
    
    [NLTickInfo setInTick:tickInfo on:NO];
    
}

+ (JSValue *)makeCallback:(JSValue *)func fromObject:(JSValue *)object withArguments:(NSArray *)args {
    JSContext   *context    = object.context;
    JSContextRef contextRef = context.JSGlobalContextRef;
    JSValueRef   callback   = func.JSValueRef;
    JSValueRef   returnVal  = JSValueMakeUndefined(contextRef);
    if (callback && JSValueIsObject(contextRef, callback) && JSObjectIsFunction(contextRef, (JSObjectRef)callback)) {
        NSUInteger  argc  = args.count;
        JSValueRef *argsv = calloc(argc, sizeof(JSValueRef));
        for (int i = 0; i < argc; i++) {
            argsv[i] = [JSValue valueWithObject:args[i] inContext:context].JSValueRef;
        }
        returnVal = JSObjectCallAsFunction(contextRef, (JSObjectRef)callback, (JSObjectRef)object.JSValueRef, argc, argsv, nil);
    }
    [NLAsync performTickCallbackInContext:context];
    return [JSValue valueWithJSValueRef:returnVal inContext:context];
}

- (void)makeCallbackFromMethod:(NSString *)method withArguments:(NSArray *)args {
    [NLAsync makeCallback:[self.object valueForProperty:method] fromObject:self.object withArguments:args];
}

- (void)makeCallbackFromIndex:(unsigned int)idx withArguments:(NSArray *)args {
    JSValue     *wrap     = self.object;
    JSContext   *context  = self.context;
    JSValueRef   callback = JSObjectGetPropertyAtIndex(context.JSGlobalContextRef, (JSObjectRef)wrap.JSValueRef, idx, nil);
    [NLAsync makeCallback:[JSValue valueWithJSValueRef:callback inContext:context] fromObject:wrap withArguments:args];
}

@end
