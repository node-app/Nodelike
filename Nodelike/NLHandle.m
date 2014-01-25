//
//  NLHandle.m
//  Nodelike
//
//  Created by Sam Rijs on 10/28/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLHandle.h"

static const unsigned int kUnref = 1;
static const unsigned int kCloseCallback = 2;

@implementation NLHandle {
    unsigned int flags;
    JSValue *persistent;
}

+ (NSMutableArray *)handleQueue {
    static NSMutableArray *queue;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        queue = [NSMutableArray new];
    });
    return queue;
}

- (void)ref {
    if (_handle != nil) {
        uv_ref(_handle);
        flags &= ~kUnref;
    }
}

- (void)unref {
    if (_handle != nil) {
        uv_unref(_handle);
        flags |= kUnref;
    }
}

- (void)close:(JSValue *)cb {
    if (_handle == nil) {
        return;
    }
    uv_close(_handle, onClose);
    _handle = nil;
    if (![cb isUndefined]) {
        [self.object setValue:cb forProperty:@"close"];
        flags |= kCloseCallback;
    }
}

- (id)initWithHandle:(uv_handle_t *)handle inContext:(JSContext *)context {
    assert(context != nil);
    self          = [super init];
    flags         = 0;
    _handle       = handle;
    _handle->data = (__bridge void *)self;
    _context      = context;
    persistent   = self.object;
    _weakValue    = [NSValue valueWithNonretainedObject:self];
    [NLHandle.handleQueue addObject:_weakValue];
    return self;
}

- (JSValue *)object {
    return [JSValue valueWithObject:self inContext:self.context];
}

- (void)dealloc {
    [NLHandle.handleQueue removeObject:_weakValue];
}

static void onClose(uv_handle_t *handle) {
    NLHandle *wrap = (__bridge NLHandle *)handle->data;
    if (wrap->flags & kCloseCallback) {
        [wrap.object invokeMethod:@"close" withArguments:@[]];
    }
    wrap->persistent = nil;
}

@end
