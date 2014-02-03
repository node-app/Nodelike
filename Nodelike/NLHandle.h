//
//  NLHandle.h
//  Nodelike
//
//  Created by Sam Rijs on 10/28/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLAsync.h"

@protocol NLHandleExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

@end

@interface NLHandle : NLAsync <NLHandleExports>

@property (readonly) uv_handle_t *handle;
@property (readonly) NSValue     *weakValue;
@property (readonly) JSValue     *object;
@property (readonly) JSContext   *context;

- (id)initWithHandle:(uv_handle_t *)handle inContext:(JSContext *)context;

@end
