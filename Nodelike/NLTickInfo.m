//
//  NLTickInfo.m
//  Nodelike
//
//  Created by Sam Rijs on 3/1/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLTickInfo.h"

#import "NSObject+Nodelike.h"

enum TickInfoFields {
    kIndex,
    kLength,
    kFieldsCount
};

static char tickInfoField, tickCallbackField, inTickField, lastThrewField;

@implementation NLTickInfo

+ (void)initObject:(JSValue *)object {
    JSContextRef context = object.context.JSGlobalContextRef;
    for (int i = 0; i< kFieldsCount; i++) {
        JSObjectSetPropertyAtIndex(context, object.JSValueRef, i, JSValueMakeNumber(context, 0), nil);
    }
}

+ (void)setObject:(JSValue *)object inContext:(JSContext *)context {
    [context.virtualMachine nodelikeSet:&tickInfoField toValue:object];
}

+ (JSValue *)getObjectInContext:(JSContext *)context {
    return [context.virtualMachine nodelikeGet:&tickInfoField];
}

+ (void)setCallback:(JSValue *)object inContext:(JSContext *)context {
    [context.virtualMachine nodelikeSet:&tickCallbackField toValue:object];
}

+ (JSValue *)getCallbackInContext:(JSContext *)context {
    return [context.virtualMachine nodelikeGet:&tickCallbackField];
}

+ (int)fieldsCount:(JSValue *)object {
    JSContextRef context = object.context.JSGlobalContextRef;
    return JSValueToNumber(context, JSObjectGetPropertyAtIndex(context, object.JSValueRef, kFieldsCount, nil), nil);
}

+ (uint32_t)index:(JSValue *)object {
    JSContextRef context = object.context.JSGlobalContextRef;
    return JSValueToNumber(context, JSObjectGetPropertyAtIndex(context, object.JSValueRef, kIndex, nil), nil);
}

+ (uint32_t)length:(JSValue *)object {
    JSContextRef context = object.context.JSGlobalContextRef;
    return JSValueToNumber(context, JSObjectGetPropertyAtIndex(context, object.JSValueRef, kLength, nil), nil);
}

+ (bool)inTick:(JSValue *)object {
    return ((NSNumber *)[object nodelikeGet:&inTickField]).boolValue;
}

+ (bool)lastThrew:(JSValue *)object {
    return ((NSNumber *)[object nodelikeGet:&inTickField]).boolValue;
}

+ (void)setIndex:(JSValue *)object index:(uint32_t)index {
    JSContextRef context = object.context.JSGlobalContextRef;
    JSObjectSetPropertyAtIndex(context, object.JSValueRef, kIndex, JSValueMakeNumber(context, index), nil);
}

+ (void)setInTick:(JSValue *)object on:(bool)on {
    [object nodelikeSet:&inTickField toValue:[NSNumber numberWithBool:on]];
}

+ (void)setLastThrew:(JSValue *)object on:(bool)on {
    [object nodelikeSet:&lastThrewField toValue:[NSNumber numberWithBool:on]];
}

@end
