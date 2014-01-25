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

JSExportAs(bind,  - (NSNumber *)bind:(longlived NSString *)address port:(NSNumber *)port flags:(NSNumber *)flags);
JSExportAs(bind6, - (NSNumber *)bind6:(longlived NSString *)address port:(NSNumber *)port flags:(NSNumber *)flags);

JSExportAs(send, - (NSNumber *)send:(JSValue *)req
                             buffer:(JSValue *)buffer offset:(NSNumber *)offset length:(NSNumber *)length
                               port:(NSNumber *)port address:(NSString *)address hasCallback:(NSNumber *)hasCallback);
JSExportAs(send6, - (NSNumber *)send6:(JSValue *)req
                               buffer:(JSValue *)buffer offset:(NSNumber *)offset length:(NSNumber *)length
                                 port:(NSNumber *)port address:(NSString *)address hasCallback:(NSNumber *)hasCallback);

- (NSNumber *)recvStart;
- (NSNumber *)recvStop;

- (NSNumber *)getsockname:(JSValue *)out;

JSExportAs(addMembership,  - (NSNumber *)addMembership:(longlived NSString *)address iface:(longlived JSValue *)iface);
JSExportAs(dropMembership, - (NSNumber *)dropMembership:(longlived NSString *)address iface:(longlived JSValue *)iface);

- (NSNumber *)setTTL:(NSNumber *)flag;
- (NSNumber *)setBroadcast:(NSNumber *)flag;
- (NSNumber *)setMulticastTTL:(NSNumber *)flag;
- (NSNumber *)setMulticastLoopback:(NSNumber *)flag;

@end

@interface NLUDP : NLHandle <NLUDPExports>

- (id)initInContext:(JSContext *)context;

@end
