//
//  NLUDP.m
//  Nodelike
//
//  Created by Sam Rijs on 1/6/14.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLUDP.h"

@implementation NLUDP {
    uv_udp_t handle;
}

+ (id)binding {
    return @{@"UDP": self.constructor};
}

- (id)init {
    return [self initInContext:JSContext.currentContext];
}

- (id)initInContext:(JSContext *)context {
    self = [super initWithHandle:(uv_handle_t *)&handle inContext:context];
    int r = uv_udp_init(NLContext.eventLoop, &handle);
    assert(r == 0);
    return self;
}

@end
