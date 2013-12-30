//
//  NLProcess.h
//  Nodelike
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol NLProcessJSExports <JSExport>

@property (readonly) NSArray      *argv;
@property (readonly) NSString     *platform;
@property (readonly) NSDictionary *env;

- (NSString *)cwd;
- (void)chdir:(NSString *)path;

- (void)exit:(NSNumber *)code;

- (void)nextTick:(JSValue *)cb;

- (id)binding:(NSString *)binding;

@end

@interface NLProcess : NSObject <NLProcessJSExports>

@property (readonly) NSArray      *argv;
@property (readonly) NSString     *platform;
@property (readonly) NSDictionary *env;

@end
