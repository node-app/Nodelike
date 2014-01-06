//
//  NLProcess.m
//  Nodelike
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLProcess.h"

@implementation NLProcess {
    uv_process_t handle;
}

+ (id)binding {
    return @{@"Process": self.constructor};
}

- (id)init {
    return [super initWithHandle:(uv_handle_t *)&handle inContext:JSContext.currentContext];
}

@end
