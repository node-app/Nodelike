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
    self = [super initWithStream:(uv_stream_t *)&handle inContext:context];
    int r = uv_tcp_init(context.eventLoop, &handle);
    assert(r == 0);
    return self;
}

- (NSNumber *)getsockname:(JSValue *)out {
    struct sockaddr_storage address;
    int addrlen = sizeof(address);
    int err = uv_tcp_getsockname(&handle,
                                 (struct sockaddr *)&address,
                                 &addrlen);
    if (err == 0) {
        const struct sockaddr* addr = (const struct sockaddr *)&address;
        AddressToJS(NLContext.currentContext, addr, out);
    }
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)getpeername:(JSValue *)out {
    struct sockaddr_storage address;
    int addrlen = sizeof(address);
    int err = uv_tcp_getpeername(&handle,
                                 (struct sockaddr *)&address,
                                 &addrlen);
    if (err == 0) {
        const struct sockaddr* addr = (const struct sockaddr *)&address;
        AddressToJS(NLContext.currentContext, addr, out);
    }
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)setNoDelay:(NSNumber *)enable {
    int err = uv_tcp_nodelay(&handle, enable.boolValue);
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)setKeepAlive:(NSNumber *)enable to:(NSNumber *)delay {
    int err = uv_tcp_keepalive(&handle, enable.boolValue, delay.unsignedIntValue);
    return [NSNumber numberWithInt:err];
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

void AddressToJS (JSContext *context, const struct sockaddr* addr, JSValue *info) {

    char ip[INET6_ADDRSTRLEN];
    const struct sockaddr_in  *a4;
    const struct sockaddr_in6 *a6;
    int port;
    
    if ([info isUndefined])
        info = [JSValue valueWithNewObjectInContext:context];
    
    switch (addr->sa_family) {
        case AF_INET6:
            a6 = (const struct sockaddr_in6 *)addr;
            uv_inet_ntop(AF_INET6, &a6->sin6_addr, ip, sizeof ip);
            port = ntohs(a6->sin6_port);
            [info setValue:[NSString stringWithUTF8String:ip] forProperty:@"address"];
            [info setValue:@"IPv6"                            forProperty:@"family"];
            [info setValue:[NSNumber numberWithInt:port]      forProperty:@"port"];
            break;
            
        case AF_INET:
            a4 = (const struct sockaddr_in *)addr;
            uv_inet_ntop(AF_INET, &a4->sin_addr, ip, sizeof ip);
            port = ntohs(a4->sin_port);
            [info setValue:[NSString stringWithUTF8String:ip] forProperty:@"address"];
            [info setValue:@"IPv4"                            forProperty:@"family"];
            [info setValue:[NSNumber numberWithInt:port]      forProperty:@"port"];
            break;
            
        default:
            [info setValue:@"" forProperty:@"address"];
    }

}

@end
