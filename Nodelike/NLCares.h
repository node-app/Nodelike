//
//  NLCares.h
//  Nodelike
//
//  Created by Sam Rijs on 10/21/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBinding.h"

@protocol NLCaresExports <JSExport>

+ (NSNumber *)isIP:(NSString *)ip;

JSExportAs(getaddrinfo, + (NSNumber *)getAddrInfo:(JSValue *)obj hostname:(NSString *)hostname family:(NSNumber *)family);

@end

@interface NLCares : NLBinding <NLCaresExports>

@end
