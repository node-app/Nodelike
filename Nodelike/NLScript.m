//
//  NLScript.m
//  Nodelike
//
//  Created by Sam Rijs on 2/19/14.
//  Copyright (c) 2014 Sam Rijs. All rights reserved.
//

#import "NLScript.h"

#import "NSObject+Nodelike.h"

@implementation NLScript

+ (id)binding {

    JSValue *script = [NLBinding makeConstructor:^(NSString *code, JSValue *options) {
        return [[NLScript alloc] initWithCode:code options:options];
    } inContext:JSContext.currentContext];
    
    /*script[@"prototype"][@"runInContext"] = ^(JSValue *context, JSValue *options) {
        return [[JSContext.currentThis toObjectOfClass:NLScript.class] runInContext:context options:options];
    };
    
    script[@"prototype"][@"runInThisContext"] = ^(JSValue *options) {
        return [[JSContext.currentThis toObjectOfClass:NLScript.class] runInThisContext:options];
    };
    
    script[@"prototype"][@"runInNewContext"] = ^(JSValue *options) {
        return [[JSContext.currentThis toObjectOfClass:NLScript.class] runInNewContext:options];
    };*/
    
    script[@"createContext"] = ^(JSValue *sandbox) {
        return [NLScript createContext:sandbox];
    };

    script[@"runInContext"] = ^(NSString *code, JSValue *context, JSValue *options) {
        return [[[NLScript alloc] initWithCode:code options:options] runInContext:context options:options];
    };

    script[@"runInThisContext"] = ^(NSString *code, JSValue *options) {
        return [[[NLScript alloc] initWithCode:code options:options] runInThisContext:options];
    };
    
    script[@"runInNewContext"] = ^(NSString *code, JSValue *options) {
        return [[[NLScript alloc] initWithCode:code options:options] runInNewContext:options];
    };

    return @{@"NodeScript": script};
}

- (instancetype)initWithCode:(NSString *)code options:(JSValue *)options {
    self = [self init];
    self.code    = code;
    self.options = options;
    return self;
}

- (JSValue *)runInContext:(JSValue *)context options:(JSValue *)options {
    JSContext *ctx = [context[@"_contextify_hidden"] toObjectOfClass:JSContext.class];
    return [ctx evaluateScript:self.code];
}

- (JSValue *)runInThisContext:(JSValue *)options {
    return [JSContext.currentContext evaluateScript:self.code];
}

- (JSValue *)runInNewContext:(JSValue *)options {
    return [[[JSContext alloc] initWithVirtualMachine:JSContext.currentContext.virtualMachine] evaluateScript:self.code];
}

- (JSValue *)createContext:(JSValue *)sandbox {
    return [NLScript createContext:sandbox];
}

+ (JSValue *)createContext:(JSValue *)sandbox {
    assert([sandbox nodelikeGet:&env_contextify_hidden] == nil);
    
    if (sandbox.isObject) {
        JSContext *ctx = [[JSContext alloc] initWithVirtualMachine:sandbox.context.virtualMachine];
        sandbox[@"_contextify_hidden"] = [JSValue valueWithObject:ctx inContext:sandbox.context];
        CloneObject(ctx, sandbox, ctx.globalObject);
        return sandbox;
    } else {
        JSValue *e = [JSValue valueWithNewErrorFromMessage:@"createContext() accept only object as first argument." inContext:sandbox.context];
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
