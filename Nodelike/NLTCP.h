//
//  NLTCP.h
//  Nodelike
//
//  Created by Sam Rijs on 12/13/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLStream.h"

@protocol NLTCPExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

- (NSNumber *)readStart;
- (NSNumber *)readStop;

- (void)open:(NSNumber *)fd;
JSExportAs(bind, - (NSNumber *)bind:(NSString *)address port:(NSNumber *)port);

@end

@interface NLTCP : NLStream <NLTCPExports>

@end
