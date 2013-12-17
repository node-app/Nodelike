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
    NLContext *context = NLContext.currentContext;
    self = [super initWithHandle:(uv_handle_t *)&handle inContext:context];
    int r = uv_tcp_init(context.eventLoop, &handle);
    assert(r == 0);
    return self;
}

- (void)open:(NSNumber *)fd {
    uv_tcp_open((uv_tcp_t *)self.handle, fd.intValue);
}

- (NSNumber *)bind:(longlived NSString *)address port:(NSNumber *)port {
    struct sockaddr_in addr;
    int err = uv_ip4_addr(address.UTF8String, port.intValue, &addr);
    if (err == 0)
        err = uv_tcp_bind(&handle, (const struct sockaddr *)&addr);
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)bind6:(longlived NSString *)address port:(NSNumber *)port {
    struct sockaddr_in6 addr;
    int err = uv_ip6_addr(address.UTF8String, port.intValue, &addr);
    if (err == 0)
        err = uv_tcp_bind(&handle, (const struct sockaddr *)&addr);
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)listen:(NSNumber *)backlog {
    int err = uv_listen((uv_stream_t *)&handle, backlog.intValue, onConnection);
    return [NSNumber numberWithInt:err];
}

static void onConnection(uv_stream_t *handle, int status) {

    JSValue *wrap = (__bridge JSValue *)(handle->data);

    NSMutableArray *args = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:status], nil];

    if (status == 0) {

        NLTCP *client_obj = [NLTCP new];

        uv_stream_t *client_handle = (uv_stream_t *)&client_obj->handle;
        if (uv_accept(handle, client_handle))
            return;

        args[1] = client_obj;

    }

    [[wrap valueForProperty:@"onconnection"] callWithArguments:args];

}

@end
