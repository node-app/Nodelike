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


@protocol NLContextifyScriptExports <JSExport>

JSExportAs(runInContext, - (JSValue *)runInContext:(JSValue *)context options:(JSValue *)options);
- (JSValue *)runInThisContext:(JSValue *)options;

@end

@interface NLContextifyScript : NLBinding <NLContextifyScriptExports>

@property NSString *code;
@property JSValue  *options;

@end

@implementation NLContextifyScript

- (instancetype)initWithCode:(NSString *)code options:(JSValue *)options {
    self = [self init];
    self.code    = code;
    self.options = options;
    return self;
}

- (JSValue *)runInContext:(JSValue *)context options:(JSValue *)options {
    JSContext *ctx = [context nodelikeGet:&env_contextify_hidden];
    assert([ctx isMemberOfClass:JSContext.class]);
    return [ctx evaluateScript:self.code];
}

- (JSValue *)runInThisContext:(JSValue *)options {
    return [JSContext.currentContext evaluateScript:self.code];
}

@end


@implementation NLContextify

+ (id)binding {
    return @{@"isContext":   ^(JSValue *obj)     { return [NLContextify isContext:obj]; },
             @"makeContext": ^(JSValue *sandbox) { return [NLContextify makeContext:sandbox]; },
             @"ContextifyScript": [NLBinding makeConstructor:^(NSString *code, JSValue *options) {
                 return [[NLContextifyScript alloc] initWithCode:code options:options];
             } inContext:JSContext.currentContext]};
}

+ (BOOL)isContext:(JSValue *)obj {
    return [[obj nodelikeGet:&env_contextify_hidden] isMemberOfClass:JSContext.class];
}

+ (JSValue *)makeContext:(JSValue *)sandbox {
    assert([sandbox nodelikeGet:&env_contextify_hidden] == nil);
    
    JSContext *ctx = [[JSContext alloc] initWithVirtualMachine:JSContext.currentContext.virtualMachine];
    [sandbox nodelikeSet:&env_contextify_hidden toValue:ctx];
    
    return sandbox;
}



@end
