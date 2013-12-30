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

#import "NLBinding.h"

@implementation NLProcess {
    NSFileManager *filemngr;
}

- (id)init {

    _platform = @"darwin";
    _argv = NSProcessInfo.processInfo.arguments;
    _env  = NSProcessInfo.processInfo.environment;

    filemngr  = [NSFileManager new];

    return [super init];

}

- (NSString *)cwd {
    return filemngr.currentDirectoryPath;
}

- (void)chdir:(NSString *)path {
    [filemngr changeCurrentDirectoryPath:path];
}

- (void)exit:(NSNumber *)code {
    exit(code.intValue);
}

- (void)nextTick:(JSValue *)cb {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [cb callWithArguments:@[]];
    });
}

- (id)binding:(NSString *)binding {
    return [NLBinding bindingForIdentifier:binding];
}

@end
