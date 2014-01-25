//
//  NLTCP.m
//  Nodelike
//
//  Created by Sam Rijs on 12/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLTCP.h"

struct connectWrap {
    uv_connect_t req;
    void        *value;
};

@implementation NLTCP {
    uv_tcp_t handle;
}

+ (id)binding {
    return @{@"TCP": self.constructor};
}

- (id)init {
    return [self initInContext:JSContext.currentContext];
}

- (id)initInContext:(JSContext *)context {
    self = [super initWithStream:(uv_stream_t *)&handle inContext:context];
    int r = uv_tcp_init(NLContext.eventLoop, &handle);
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
    uv_tcp_open(&handle, fd.intValue);
}

- (NSNumber *)bind:(longlived NSString *)address port:(NSNumber *)port {
    struct sockaddr_in addr;
    return bindCommon(uv_ip4_addr(address.UTF8String, port.intValue, &addr),
                      &handle, (const struct sockaddr *)&addr);
}

- (NSNumber *)bind6:(longlived NSString *)address port:(NSNumber *)port {
    struct sockaddr_in6 addr;
    return bindCommon(uv_ip6_addr(address.UTF8String, port.intValue, &addr),
                      &handle, (const struct sockaddr *)&addr);
}

static NSNumber *bindCommon (int err, uv_tcp_t *handle, const struct sockaddr *addr) {
    if (err == 0)
        err = uv_tcp_bind(handle, addr);
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)listen:(NSNumber *)backlog {
    int err = uv_listen((uv_stream_t *)&handle, backlog.intValue, onConnection);
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)connect:(JSValue *)obj address:(longlived NSString *)address port:(NSNumber *)port {
    struct sockaddr_in addr;
    return connectCommon(uv_ip4_addr(address.UTF8String, port.intValue, &addr),
                         obj, &handle, (const struct sockaddr *)&addr);
}

- (NSNumber *)connect6:(JSValue *)obj address:(longlived NSString *)address port:(NSNumber *)port {
    struct sockaddr_in6 addr;
    return connectCommon(uv_ip6_addr(address.UTF8String, port.intValue, &addr),
                         obj, &handle, (const struct sockaddr *)&addr);
}

static NSNumber *connectCommon (int err, JSValue *obj, uv_tcp_t *handle, const struct sockaddr *addr) {
    if (err == 0) {
        struct connectWrap *wrap = malloc(sizeof(struct connectWrap));
        wrap->value    = (void *)CFBridgingRetain(obj);
        wrap->req.data = wrap;
        err = uv_tcp_connect(&wrap->req, handle, addr, afterConnect);
        if (err)
            free(wrap);
    }
    return [NSNumber numberWithInt:err];
}

static void afterConnect(uv_connect_t* req, int status) {
    
    JSValue  *connectWrap = CFBridgingRelease(((struct connectWrap *)req->data)->value);
    NLStream *wrap        = (__bridge NLStream *)(req->handle->data);

    free(req->data);
    
    [connectWrap invokeMethod:@"oncomplete" withArguments:@[[NSNumber numberWithInt:status],
                                                            wrap,
                                                            connectWrap,
                                                            [NSNumber numberWithBool:YES],
                                                            [NSNumber numberWithBool:YES]]];

}

static void onConnection(uv_stream_t *handle, int status) {

    NLStream *wrap = (__bridge NLStream *)handle->data;

    NSMutableArray *args = [NSMutableArray arrayWithObject:[NSNumber numberWithInt:status]];

    if (status == 0) {

        NLTCP *client_obj = [[NLTCP alloc] initInContext:wrap.context];

        uv_stream_t *client_handle = (uv_stream_t *)&client_obj->handle;
        if (uv_accept(handle, client_handle))
            return;

        [args addObject:client_obj];

    }

    [wrap.object invokeMethod:@"onconnection" withArguments:args];

}

static JSValue *AddressToJS (JSContext *context, const struct sockaddr* addr, JSValue *info) {
    
    char ip[INET6_ADDRSTRLEN];
    const struct sockaddr_in  *a4;
    const struct sockaddr_in6 *a6;
    int port;
    
    if (!info || [info isUndefined])
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
    
    return info;
    
}

@end
