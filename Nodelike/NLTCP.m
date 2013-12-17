//
//  NLTCP.m
//  Nodelike
//
//  Created by Sam Rijs on 12/13/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLTCP.h"

@implementation NLTCP {
    uv_tcp_t handle;
}

+ (id)binding {
    return @{@"TCP": self.constructor};
}

- (id)init {
    NLContext *context = [NLContext currentContext];
    self = [super initWithHandle:(uv_handle_t *)&handle inContext:context];
    int r = uv_tcp_init(context.eventLoop, &handle);
    assert(r == 0);
    return self;
}

- (void)open:(NSNumber *)fd {
    uv_tcp_open((uv_tcp_t *)self.handle, [fd intValue]);
}

- (NSNumber *)bind:(longlived NSString *)address port:(NSNumber *)port {
    struct sockaddr_in addr;
    int err = uv_ip4_addr([address UTF8String], [port intValue], &addr);
    if (err == 0)
        err = uv_tcp_bind(&handle, (const struct sockaddr *)&addr);
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)bind6:(longlived NSString *)address port:(NSNumber *)port {
    struct sockaddr_in6 addr;
    int err = uv_ip6_addr([address UTF8String], [port intValue], &addr);
    if (err == 0)
        err = uv_tcp_bind(&handle, (const struct sockaddr *)&addr);
    return [NSNumber numberWithInt:err];
}

@end
