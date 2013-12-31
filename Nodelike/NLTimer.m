//
//  NLTimer.m
//  Nodelike
//
//  Created by Sam Rijs on 10/30/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLTimer.h"

static const unsigned int kOnTimeout = 0;

@implementation NLTimer {
    uv_timer_t handle;
}

+ (id)binding {
    JSValue   *timer     = self.constructor;
    timer[@"kOnTimeout"] = [NSNumber numberWithUnsignedInt:kOnTimeout];
    timer[@"now"]        = ^{
        uv_loop_t *eventLoop = NLContext.eventLoop;
        uv_update_time(eventLoop);
        return [NSNumber numberWithDouble:uv_now(eventLoop)];
    };
    return @{@"Timer": timer};
}

- (id)init {
    self = [super initWithHandle:(uv_handle_t *)&handle inContext:JSContext.currentContext];
    int r = uv_timer_init(NLContext.eventLoop, &handle);
    assert(r == 0);
    return self;
}

- (NSNumber *)start:(NSNumber *)timeout repeat:(NSNumber *)repeat {
    return [NSNumber numberWithInt:uv_timer_start(&handle, onTimeout, timeout.intValue, repeat.intValue)];
}

- (NSNumber *)stop {
    return [NSNumber numberWithInt:uv_timer_stop(&handle)];
}

- (NSNumber *)setRepeat:(NSNumber *)repeat {
    uv_timer_set_repeat(&handle, repeat.intValue);
    return @0;
}

- (NSNumber *)getRepeat {
    return [NSNumber numberWithDouble:uv_timer_get_repeat(&handle)];
}

- (NSNumber *)again {
    return [NSNumber numberWithInt:uv_timer_again(&handle)];
}

static void onTimeout(uv_timer_t *handle, int status) {
    JSValue     *wrap       = ((__bridge NLHandle *)handle->data).object;
    JSObjectRef  wrapRef    = (JSObjectRef)(wrap.JSValueRef);
    JSContextRef contextRef = wrap.context.JSGlobalContextRef;
    JSValueRef   callback   = JSObjectGetPropertyAtIndex(contextRef, wrapRef, kOnTimeout, nil);
    if (callback && JSValueIsObject(contextRef, callback) && JSObjectIsFunction(contextRef, (JSObjectRef)callback)) {
        JSValueRef arg = JSValueMakeNumber(contextRef, status);
        JSObjectCallAsFunction(contextRef, (JSObjectRef)callback, wrapRef, 1, &arg, nil);
    }
}

@end
