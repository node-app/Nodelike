//
//  NLTCP.m
//  Nodelike
//
//  Created by Sam Rijs on 12/13/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLTCP.h"

@implementation NLTCP

- (void)open:(NSNumber *)fd {
    uv_tcp_open((uv_tcp_t *)self.handle, [fd intValue]);
}

- (NSNumber *)bind:(NSString *)address port:(NSNumber *)port {
    struct sockaddr_in addr;
    int err = uv_ip4_addr([address UTF8String], [port intValue], &addr);
    if (err == 0)
        err = uv_tcp_bind((uv_tcp_t *)self.handle, (const struct sockaddr *)&addr);
    return [NSNumber numberWithInt:err];
}

@end
