//
//  NSObject+Nodelike.h
//  Nodelike
//
//  Created by Sam Rijs on 2/2/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <JavaScriptCore/JavaScriptCore.h>

extern char env_buffer_constructor;
extern char env_contextify_hidden;
extern char env_process_object;

@interface NSObject (Nodelike)

- (id)nodelikeGet:(void *)key;
- (void)nodelikeSet:(void *)key toValue:(id)value;

@end
