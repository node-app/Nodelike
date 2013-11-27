//
//  NLStream.h
//  Nodelike
//
//  Created by Sam Rijs on 11/27/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLHandle.h"

@protocol NLStreamExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

- (NSNumber *)readStart;

@end

@interface NLStream : NLHandle <NLStreamExports>

@end
