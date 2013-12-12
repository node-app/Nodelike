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

@end
