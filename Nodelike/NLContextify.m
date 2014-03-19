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

#if USE_TIMEOUTS
JS_EXPORT void JSContextGroupSetExecutionTimeLimit(JSContextGroupRef, double limit, void*, void* context) CF_AVAILABLE(10_6, 7_0);
JS_EXPORT void JSContextGroupClearExecutionTimeLimit(JSContextGroupRef) CF_AVAILABLE(10_6, 7_0);
#endif

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

- (JSValue *)runInJSContext:(JSContext*)context options:(JSValue *)options {
    JSValue * opt = options.isUndefined? self.options : options;;
#if USE_TIMEOUTS
    int hasTimeout = !opt.isUndefined && [opt hasProperty:@"timeout"];
    if (hasTimeout) {
        JSValue * timeout = opt[@"timeout"];
	double dtimeout = [timeout toDouble];
	if (dtimeout <= 0)
		return [context evaluateScript:@"throw RangeError('timeout must be positive');"];
        JSContextRef jsctx = context.JSGlobalContextRef;
        JSContextGroupRef grp = JSContextGetGroup(jsctx);
        JSContextGroupSetExecutionTimeLimit(grp, dtimeout / 1000.0, nil, jsctx);
    }
#endif
    JSValue *result = [context evaluateScript:self.code];
#if USE_TIMEOUTS
    if (hasTimeout) {
        JSContextRef jsctx = context.JSGlobalContextRef;
        JSContextGroupRef grp = JSContextGetGroup(jsctx);
        JSContextGroupClearExecutionTimeLimit(grp);
    }
#endif
    JSValue * e = context.exception;
    if (e) {
#if USE_TIMEOUTS
	if ([e.toString isEqualToString:@"JavaScript execution terminated."])
		[context evaluateScript:@"throw Error('Script execution timed out.')"];
#endif	
	JSContext.currentContext.exception = context.exception;
    }
    return result;
}

- (JSValue *)runInContext:(JSValue *)context options:(JSValue *)options {
    if (context.isUndefined)
        return [context.context evaluateScript:@"throw TypeError('context cannot be undefined.');"];
    if (!context.isObject)
        return [context.context evaluateScript:@"throw TypeError('contextifiedSandbox argument must be an object.');"];
    
    NSLog(@"run: %@ %@", context[@"_contextifyHidden"], self.code);
    
    JSContext *ctx = [context[@"_contextifyHidden"] toObjectOfClass:JSContext.class];
    
    if (!ctx)
            return [context.context evaluateScript:@"throw TypeError('sandbox argument must have been converted to a context.');"]; 
    JSValue * result = [self runInJSContext:ctx options:options];
    JSValue *sandbox = [ctx nodelikeGet:&contextify_sandbox];
    CloneObject(context.context, ctx.globalObject, sandbox);
    return result;
    
}

- (JSValue *)runInThisContext:(JSValue *)options {
    return [self runInJSContext:JSContext.currentContext options:options];
}

- (JSValue *)runInNewContext:(JSValue *)sandbox options:(JSValue *)options {
    JSValue * ctx = [NLContextify makeContext:sandbox.isUndefined?
                     [JSValue valueWithNewObjectInContext:JSContext.currentContext] : sandbox];
    return [self runInContext:ctx options:options];
}

+ (JSValue *)isContext:(JSValue *)obj {
    JSContext * ctx = JSContext.currentContext;
    if (!obj.isObject)
	return [ctx evaluateScript:@"throw TypeError('contextifiedSandbox argument must be an object.');"];
    return [JSValue valueWithBool:obj[@"_contextifyHidden"].isObject inContext:ctx];
}

+ (JSValue *)makeContext:(JSValue *)sandbox {
    if (sandbox.isObject) {
        JSContext *ctx = [[JSContext alloc] initWithVirtualMachine:sandbox.context.virtualMachine];
	[sandbox defineProperty:@"_contextifyHidden" descriptor:@{
                                                                  JSPropertyDescriptorWritableKey : @YES,
                                                                  JSPropertyDescriptorEnumerableKey: @NO,
                                                                  }];
        sandbox[@"_contextifyHidden"] = [JSValue valueWithObject:ctx inContext:sandbox.context];
        CloneObject(sandbox.context, sandbox, ctx.globalObject);
        [ctx nodelikeSet:&contextify_sandbox toValue:sandbox];
        
        return sandbox;
    } else 
	return [sandbox.context evaluateScript:@"throw TypeError('sandbox argument must be an object.');"];
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
