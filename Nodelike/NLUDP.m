//
//  NLUDP.m
//  Nodelike
//
//  Created by Sam Rijs on 1/6/14.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLUDP.h"

#import "NLBuffer.h"

struct sendWrap {
    uv_udp_send_t req;
    const void   *value;
    bool          hasCallback;
};

@implementation NLUDP {
    uv_udp_t handle;
}

+ (id)binding {
    return @{@"UDP": self.constructor};
}

- (id)init {
    return [self initInContext:JSContext.currentContext];
}

- (id)initInContext:(JSContext *)context {
    self = [super initWithHandle:(uv_handle_t *)&handle inContext:context];
    int r = uv_udp_init(NLContext.eventLoop, &handle);
    assert(r == 0);
    return self;
}

- (NSNumber *)getsockname:(JSValue *)out {
    struct sockaddr_storage address;
    int addrlen = sizeof(address);
    int err = uv_udp_getsockname(&handle,
                                 (struct sockaddr *)&address,
                                 &addrlen);
    if (err == 0) {
        const struct sockaddr* addr = (const struct sockaddr *)&address;
        AddressToJS(NLContext.currentContext, addr, out);
    }
    return [NSNumber numberWithInt:err];
}

- (void)open:(NSNumber *)fd {
    uv_udp_open(&handle, fd.intValue);
}

- (NSNumber *)bind:(longlived NSString *)address port:(NSNumber *)port flags:(NSNumber *)flags {
    struct sockaddr_in addr;
    return bindCommon(uv_ip4_addr(address.UTF8String, port.intValue, &addr),
                      &handle, (const struct sockaddr *)&addr, flags.intValue);
}

- (NSNumber *)bind6:(longlived NSString *)address port:(NSNumber *)port flags:(NSNumber *)flags {
    struct sockaddr_in6 addr;
    return bindCommon(uv_ip6_addr(address.UTF8String, port.intValue, &addr),
                      &handle, (const struct sockaddr *)&addr, flags.intValue);
}

static NSNumber *bindCommon (int err, uv_udp_t *handle, const struct sockaddr *addr, int flags) {
    if (err == 0)
        err = uv_udp_bind(handle, addr, flags);
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)setTTL:(NSNumber *)flag {
    return [NSNumber numberWithInt:uv_udp_set_ttl(&handle, flag.intValue)];
}

- (NSNumber *)setBroadcast:(NSNumber *)flag {
    return [NSNumber numberWithInt:uv_udp_set_broadcast(&handle, flag.intValue)];
}

- (NSNumber *)setMulticastTTL:(NSNumber *)flag {
    return [NSNumber numberWithInt:uv_udp_set_multicast_ttl(&handle, flag.intValue)];
}

- (NSNumber *)setMulticastLoopback:(NSNumber *)flag {
    return [NSNumber numberWithInt:uv_udp_set_multicast_loop(&handle, flag.intValue)];
}

- (NSNumber *)addMembership:(longlived NSString *)address iface:(longlived JSValue *)iface {
    const char* iface_cstr = NULL;
    if (!iface.isUndefined && !iface.isNull) {
        iface_cstr = iface.toString.UTF8String;
    }
    int err = uv_udp_set_membership(&handle, address.UTF8String, iface_cstr, UV_JOIN_GROUP);
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)dropMembership:(longlived NSString *)address iface:(longlived JSValue *)iface {
    const char* iface_cstr = NULL;
    if (!iface.isUndefined && !iface.isNull) {
        iface_cstr = iface.toString.UTF8String;
    }
    int err = uv_udp_set_membership(&handle, address.UTF8String, iface_cstr, UV_LEAVE_GROUP);
    return [NSNumber numberWithInt:err];
}

static NSNumber *sendCommon (JSValue *req, JSValue *buffer,
                         unsigned int offset, unsigned int length,
                         unsigned int port, bool hasCallback,
                         uv_udp_t *handle, const struct sockaddr *addr, int err) {
    
    if (err != 0) {
        return [NSNumber numberWithInt:err];
    }
    
    struct sendWrap *sendWrap = malloc(sizeof(sendWrap));
    sendWrap->value = CFBridgingRetain(req);
    sendWrap->hasCallback = hasCallback;
    sendWrap->req.data = sendWrap;
    
    uv_buf_t buf = uv_buf_init([NLBuffer getData:buffer ofSize:length] + offset, length);
    
    err = uv_udp_send(&sendWrap->req, handle, &buf, 1, addr, onSend);
    
    if (err) {
        CFBridgingRelease(sendWrap->value);
        free(sendWrap);
    }
    
    return [NSNumber numberWithInt:err];
    
}

- (NSNumber *)send:(JSValue *)req
            buffer:(JSValue *)buffer offset:(NSNumber *)offset length:(NSNumber *)length
              port:(NSNumber *)port address:(NSString *)address hasCallback:(NSNumber *)hasCallback {
    struct sockaddr_in addr;
    return sendCommon(req, buffer, offset.unsignedIntValue, length.unsignedIntValue,
                      port.unsignedIntValue, hasCallback.boolValue,
                      &handle, (const struct sockaddr *)&addr,
                      uv_ip4_addr(address.UTF8String, port.intValue, &addr));
}

- (NSNumber *)send6:(JSValue *)req
             buffer:(JSValue *)buffer offset:(NSNumber *)offset length:(NSNumber *)length
               port:(NSNumber *)port address:(NSString *)address hasCallback:(NSNumber *)hasCallback {
    struct sockaddr_in6 addr;
    return sendCommon(req, buffer, offset.unsignedIntValue, length.unsignedIntValue,
                      port.unsignedIntValue, hasCallback.boolValue,
                      &handle, (const struct sockaddr *)&addr,
                      uv_ip6_addr(address.UTF8String, port.intValue, &addr));
}

- (NSNumber *)recvStart {
    int err = uv_udp_recv_start(&handle, onAlloc, onRecv);
    // UV_EALREADY means that the socket is already bound but that's okay
    if (err == UV_EALREADY)
        err = 0;
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)recvStop {
    int err = uv_udp_recv_stop(&handle);
    return [NSNumber numberWithInt:err];
}

static void onSend (uv_udp_send_t* req, int status) {
    struct sendWrap *sendWrap = req->data;
    JSValue *value = (__bridge JSValue *)(sendWrap->value);
    if (sendWrap->hasCallback) {
        [value invokeMethod:@"oncomplete" withArguments:@[[NSNumber numberWithInt:status]]];
    }
    free(sendWrap);
}

static void onAlloc (uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf) {
    buf->base = malloc(suggested_size);
    buf->len  = suggested_size;
}

static void onRecv (uv_udp_t* handle, ssize_t nread, const uv_buf_t* buf, const struct sockaddr* addr, unsigned int flags) {
    if (nread == 0) {
        if (buf->base != NULL)
        free(buf->base);
        return;
    }
    
    NLUDP *wrap = (__bridge NLUDP *)(handle->data);
    JSValue *wrapObj = wrap.object;
    
    NSMutableArray *args = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:(int)nread], wrapObj, nil];
    
    if (nread < 0) {
        if (buf->base != NULL)
        free(buf->base);
        [wrapObj invokeMethod:@"onmessage" withArguments:args];
        return;
    }
    
    char* base = realloc(buf->base, nread);
    
    args[2] = [NLBuffer useData:base ofLength:nread inContext:wrapObj.context];
    args[3] = AddressToJS(wrap.context, addr, NULL);
    [wrapObj invokeMethod:@"onmessage" withArguments:args];

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
