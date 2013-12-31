//
//  NLTCP.h
//  Nodelike
//
//  Created by Sam Rijs on 12/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLStream.h"

@protocol NLTCPExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

- (NSNumber *)readStart;
- (NSNumber *)readStop;

- (NSNumber *)getsockname:(JSValue *)out;
- (NSNumber *)getpeername:(JSValue *)out;

- (NSNumber *)setNoDelay:(NSNumber *)enable;
JSExportAs(setKeepAlive, - (NSNumber *)setKeepAlive:(NSNumber *)enable to:(NSNumber *)delay);

- (void)open:(NSNumber *)fd;

JSExportAs(bind,  - (NSNumber *)bind:(NSString *)address port:(NSNumber *)port);
JSExportAs(bind6, - (NSNumber *)bind6:(NSString *)address port:(NSNumber *)port);

- (NSNumber *)listen:(NSNumber *)backlog;

JSExportAs(connect,  - (NSNumber *)connect:(JSValue *)obj address:(NSString *)address port:(NSNumber *)port);
JSExportAs(connect6, - (NSNumber *)connect6:(JSValue *)obj address:(NSString *)address port:(NSNumber *)port);

@end

@interface NLTCP : NLStream <NLTCPExports>

- (id)initInContext:(JSContext *)context;

@end
