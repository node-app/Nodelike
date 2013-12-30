//
//  NLTimer.h
//  Nodelike
//
//  Created by Sam Rijs on 10/30/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLHandle.h"

@protocol NLTimerExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

JSExportAs(start, - (NSNumber *)start:(NSNumber *)timeout repeat:(NSNumber *)repeat);
- (NSNumber *)stop;
- (NSNumber *)setRepeat:(NSNumber *)repeat;
- (NSNumber *)getRepeat;
- (NSNumber *)again;

@end

@interface NLTimer : NLHandle <NLTimerExports>

@end
