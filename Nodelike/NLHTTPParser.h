//
//  NLHTTPParser.h
//  Nodelike
//
//  Created by Sam Rijs on 1/8/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBinding.h"

@protocol NLHTTPParserExports <JSExport>

- (JSValue *)execute:(JSValue *)buffer;
- (JSValue *)finish;

- (void)reinitialize:(NSNumber *)type;
- (void)pause;
- (void)resume;

@end

@interface NLHTTPParser : NLBinding <NLHTTPParserExports>

@end
