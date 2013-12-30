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
        _closeCallback = cb;
        flags |= kCloseCallback;
    }
}

- (id)initWithHandle:(uv_handle_t *)handle inContext:(JSContext *)context {
    self          = [super init];
    flags         = 0;
    _handle       = handle;
    _handle->data = (void *)CFBridgingRetain([JSValue valueWithObject:self inContext:context]);
    _weakValue    = [NSValue valueWithNonretainedObject:self];
    [NLHandle.handleQueue addObject:_weakValue];
    return self;
}

- (void)dealloc {
    [NLHandle.handleQueue removeObject:self.weakValue];
}

static void onClose(uv_handle_t *handle) {
    NLHandle *wrap = [(JSValue *)CFBridgingRelease(handle->data) toObjectOfClass:NLHandle.class];
    if (wrap->flags & kCloseCallback) {
        [wrap.closeCallback callWithArguments:@[]];
    }
}

@end
