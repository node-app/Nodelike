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

static char asyncListenerFlagObject,
            asyncListenerRunFunction,
            asyncListenerLoadFunction,
            asyncListenerUnloadFunction;

enum AsyncListenerFields {
    kHasListener,
    kFieldsCount
};

enum AsyncFlags {
    NO_OPTIONS = 0,
    HAS_ASYNC_LISTENER = 1
};

@implementation NLAsync {
    uint32_t asyncFlags;
}

- (instancetype)initInContext:(JSContext *)context {
    self = [super init];
    _context = context;
    
    asyncFlags = NO_OPTIONS;
    
    if (![NLAsync hasAsyncListener:context])
        return self;
    
    [NLAsync performCallback:[NLAsync asyncListenerRunFunction:context]
                  fromObject:[context.virtualMachine nodelikeGet:&env_process_object]
               withArguments:@[self]];
    
    asyncFlags |= HAS_ASYNC_LISTENER;
    
    return self;
}

- (JSValue *)object {
    return [JSValue valueWithObject:self inContext:self.context];
}

+ (JSValue *)asyncListenerRunFunction:(JSContext *)context {
    return [context.virtualMachine nodelikeGet:&asyncListenerRunFunction];
}

+ (JSValue *)asyncListenerLoadFunction:(JSContext *)context {
    return [context.virtualMachine nodelikeGet:&asyncListenerLoadFunction];
}

+ (JSValue *)asyncListenerUnloadFunction:(JSContext *)context {
    return [context.virtualMachine nodelikeGet:&asyncListenerUnloadFunction];
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
    
    [NLAsync performCallback:[NLTickInfo getCallbackInContext:context]
                  fromObject:[context.virtualMachine nodelikeGet:&env_process_object]
               withArguments:@[]];
    
    [NLTickInfo setInTick:tickInfo on:NO];
    
}

+ (JSValue *)performCallback:(JSValue *)func fromObject:(JSValue *)object withArguments:(NSArray *)args {
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
        free(argsv);
    }
    
    return [JSValue valueWithJSValueRef:returnVal inContext:context];
}

+ (JSValue *)makeGlobalCallback:(JSValue *)func fromObject:(JSValue *)object withArguments:(NSArray *)args {
    JSContext *context = object.context;
    JSValue   *process = [context.virtualMachine nodelikeGet:&env_process_object];
    
    bool hasAsyncQueue = [object hasProperty:@"_asyncQueue"];
    if (hasAsyncQueue) {
        [NLAsync performCallback:[NLAsync asyncListenerLoadFunction:context]
                      fromObject:process
                   withArguments:@[object]];
    }
    
    JSValue *returnVal = [NLAsync performCallback:func fromObject:object withArguments:args];
    
    if (hasAsyncQueue) {
        [NLAsync performCallback:[NLAsync asyncListenerUnloadFunction:context]
                      fromObject:process
                   withArguments:@[object]];
    }
    
    [NLAsync performTickCallbackInContext:context];

    return returnVal;
}

- (JSValue *)makeCallback:(JSValue *)func withArguments:(NSArray *)args {
    JSContext *context = self.context;
    JSValue   *process = [context.virtualMachine nodelikeGet:&env_process_object];
    
    bool hasAsyncQueue = [self hasAsyncListener];
    if (hasAsyncQueue) {
        [NLAsync performCallback:[NLAsync asyncListenerLoadFunction:context]
                      fromObject:process
                   withArguments:@[self]];
    }
    
    JSValue *returnVal = [NLAsync performCallback:func fromObject:self.object withArguments:args];
    
    if (hasAsyncQueue) {
        [NLAsync performCallback:[NLAsync asyncListenerUnloadFunction:context]
                      fromObject:process
                   withArguments:@[self]];
    }
    
    [NLAsync performTickCallbackInContext:context];

    return returnVal;
}


- (void)makeCallbackFromMethod:(NSString *)method withArguments:(NSArray *)args {
    [self makeCallback:[self.object valueForProperty:method] withArguments:args];
}

- (void)makeCallbackFromIndex:(unsigned int)idx withArguments:(NSArray *)args {
    JSValue     *wrap     = self.object;
    JSContext   *context  = self.context;
    JSValueRef   callback = JSObjectGetPropertyAtIndex(context.JSGlobalContextRef, (JSObjectRef)wrap.JSValueRef, idx, nil);
    [self makeCallback:[JSValue valueWithJSValueRef:callback inContext:context] withArguments:args];
}

+ (void)setupAsyncListener:(JSValue *)flagObj run:(JSValue *)run load:(JSValue *)load unload:(JSValue *)unload {
    JSContext   *context    = flagObj.context;
    JSContextRef contextRef = context.JSGlobalContextRef;
    JSValueRef   flagObjRef = flagObj.JSValueRef;
    for (int i = 0; i < kFieldsCount; i++) {
        JSObjectSetPropertyAtIndex(contextRef, (JSObjectRef)flagObjRef, i, JSValueMakeNumber(contextRef, 0), nil);
    }
    [context.virtualMachine nodelikeSet:&asyncListenerFlagObject     toValue:flagObj];
    [context.virtualMachine nodelikeSet:&asyncListenerRunFunction    toValue:run];
    [context.virtualMachine nodelikeSet:&asyncListenerLoadFunction   toValue:load];
    [context.virtualMachine nodelikeSet:&asyncListenerUnloadFunction toValue:unload];
}

- (bool)hasAsyncListener {
    return asyncFlags & HAS_ASYNC_LISTENER;
}

+ (bool)hasAsyncListener:(JSContext *)context {
    JSValueRef   flagObjRef  = ((JSValue *)[context.virtualMachine nodelikeGet:&asyncListenerFlagObject]).JSValueRef;
    JSContextRef contextRef  = context.JSGlobalContextRef;
    JSValueRef   hasListener = JSObjectGetPropertyAtIndex(contextRef, (JSObjectRef)flagObjRef, kHasListener, nil);
    return JSValueToNumber(contextRef, hasListener, nil) > 0;
}

@end
