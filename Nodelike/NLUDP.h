//
//  NLUDP.h
//  Nodelike
//
//  Created by Sam Rijs on 1/6/14.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLHandle.h"

@protocol NLUDPExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

@end

@interface NLUDP : NLHandle <NLUDPExports>

- (id)initInContext:(JSContext *)context;

@end
