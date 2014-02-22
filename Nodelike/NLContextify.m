//
//  NLContextify.m
//  Nodelike
//
//  Created by Sam Rijs on 2/2/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLContextify.h"

#import "NSObject+Nodelike.h"

static char contextify_sandbox;

@implementation NLContextify

+ (id)binding {
    return @{@"isContext":   ^(JSValue *obj)     { return [NLContextify isContext:obj]; },
             @"makeContext": ^(JSValue *sandbox) { return [NLContextify makeContext:sandbox]; },
             @"ContextifyScript": [NLBinding makeConstructor:^(NSString *code, JSValue *options) {
                 return [[NLContextify alloc] initWithCode:code options:options];
             } inContext:JSContext.currentContext]};
}

- (instancetype)initWithCode:(NSString *)code options:(JSValue *)options {
    self = [self init];
    self.code    = code;
    self.options = options;
    return self;
}

- (JSValue *)runInContext:(JSValue *)context options:(JSValue *)options {
    
    NSLog(@"run: %@ %@", context[@"_contextifyHidden"], self.code);
    
    if (!context.isObject) {
        return context.context.exception = [JSValue valueWithNewErrorFromMessage:@"contextifiedSandbox argument must be an object." inContext:context.context];
    }
    
    JSContext *ctx = [context[@"_contextifyHidden"] toObjectOfClass:JSContext.class];
    
    if (!ctx) {
        return context.context.exception = [JSValue valueWithNewErrorFromMessage:@"sandbox argument must have been converted to a context." inContext:context.context];
    }
    
    JSValue *result = [ctx evaluateScript:self.code];
    
    JSValue *sandbox = [ctx nodelikeGet:&contextify_sandbox];
    
    CloneObject(context.context, ctx.globalObject, sandbox);
    
    return result;
    
}

- (JSValue *)runInThisContext:(JSValue *)options {
    return [JSContext.currentContext evaluateScript:self.code];
}

- (JSValue *)runInNewContext:(JSValue *)options {
    return [[[JSContext alloc] initWithVirtualMachine:JSContext.currentContext.virtualMachine] evaluateScript:self.code];
}

+ (BOOL)isContext:(JSValue *)obj {
    return obj[@"_contextifyHidden"].isObject;
}

+ (JSValue *)makeContext:(JSValue *)sandbox {
    
    if (sandbox.isObject) {
        JSContext *ctx = [[JSContext alloc] initWithVirtualMachine:sandbox.context.virtualMachine];
        sandbox[@"_contextifyHidden"] = [JSValue valueWithObject:ctx inContext:sandbox.context];
        CloneObject(sandbox.context, sandbox, ctx.globalObject);
        [ctx nodelikeSet:&contextify_sandbox toValue:sandbox];
        return sandbox;
    } else {
        JSValue *e = [JSValue valueWithNewErrorFromMessage:@"sandbox argument must be an object." inContext:sandbox.context];
        sandbox.context.exception = e;
        return e;
    }

}

static void CloneObject(JSContext *recv, JSValue *source, JSValue *target) {
    
    JSValue *cloneObjectMethod = [recv evaluateScript:@
                                  "(function(source, target) {\n"
                                  "Object.getOwnPropertyNames(source).forEach(function(key) {\n"
                                  "try {\n"
                                  "var desc = Object.getOwnPropertyDescriptor(source, key);\n"
                                  "if (desc.value === source) desc.value = target;\n"
                                  "Object.defineProperty(target, key, desc);\n"
                                  "} catch (e) {\n"
                                  "// Catch sealed properties errors\n"
                                  "}\n"
                                  "});\n"
                                  "})"];
    
    [cloneObjectMethod callWithArguments:@[source, target]];
    
}

@end
