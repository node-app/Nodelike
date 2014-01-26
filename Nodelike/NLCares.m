//
//  NLCares.m
//  Nodelike
//
//  Created by Sam Rijs on 10/21/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLCares.h"

struct getaddrinfoWrap {
    uv_getaddrinfo_t req;
    void            *value;
};

static int isIP(const char *ip) {
    struct in6_addr address_buffer;
    int rc = 0;
    if (uv_inet_pton(AF_INET, ip, &address_buffer) == 0)
        rc = 4;
    else if (uv_inet_pton(AF_INET6, ip, &address_buffer) == 0)
        rc = 6;
    return rc;
}

@implementation NLCares

+ (NSNumber *)isIP:(longlived NSString *)ip {
    return [NSNumber numberWithInt:isIP(ip.UTF8String)];
}

+ (NSNumber *)getAddrInfo:(JSValue *)obj hostname:(NSString *)hostname family:(NSNumber *)familyNum {

    int family;
    switch (familyNum.intValue) {
        case 0:
            family = AF_UNSPEC;
            break;
        case 4:
            family = AF_INET;
            break;
        case 6:
            family = AF_INET6;
            break;
        default:
            assert(0 && "bad address family");
            abort();
    }
    
    struct getaddrinfoWrap *wrap = malloc(sizeof(struct getaddrinfoWrap));
    wrap->value    = (void *)CFBridgingRetain(obj);
    wrap->req.data = wrap;
    
    struct addrinfo hints;
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = family;
    hints.ai_socktype = SOCK_STREAM;
    
    int err = uv_getaddrinfo(NLContext.eventLoop,
                             &wrap->req,
                             afterGetAddrInfo,
                             hostname.UTF8String,
                             NULL,
                             &hints);

    if (err) {
        CFBridgingRelease(wrap->value);
        free(wrap);
    }
    
    return [NSNumber numberWithInt:err];

}

static void afterGetAddrInfo(uv_getaddrinfo_t* req, int status, struct addrinfo* res) {
    struct getaddrinfoWrap* wrap = req->data;
    JSValue *object = CFBridgingRelease(wrap->value);
    
    if (status == 0) {
        // Success
        struct addrinfo *address;
        int n = 0;
        
        // Count the number of responses.
        for (address = res; address; address = address->ai_next) {
            n++;
        }
        
        // Create the response array.
        NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:n];
        
        char ip[INET6_ADDRSTRLEN];
        const char *addr;
        
        n = 0;
        
        // Iterate over the IPv4 responses again this time creating javascript
        // strings for each IP and filling the results array.
        address = res;
        while (address) {
            assert(address->ai_socktype == SOCK_STREAM);
            
            // Ignore random ai_family types.
            if (address->ai_family == AF_INET) {
                // Juggle pointers
                addr = (char *)(&(((struct sockaddr_in *)(address->ai_addr))->sin_addr));
                int err = uv_inet_ntop(address->ai_family,
                                       addr,
                                       ip,
                                       INET6_ADDRSTRLEN);
                if (err)
                    continue;
                
                // Create JavaScript string
                [results setObject:[NSString stringWithUTF8String:ip] atIndexedSubscript:n];
                n++;
            }
            
            // Increment
            address = address->ai_next;
        }
        
        // Iterate over the IPv6 responses putting them in the array.
        address = res;
        while (address) {
            assert(address->ai_socktype == SOCK_STREAM);
            
            // Ignore random ai_family types.
            if (address->ai_family == AF_INET6) {
                // Juggle pointers
                addr = (char *)(&(((struct sockaddr_in6 *)(address->ai_addr))->sin6_addr));
                int err = uv_inet_ntop(address->ai_family,
                                       addr,
                                       ip,
                                       INET6_ADDRSTRLEN);
                if (err)
                    continue;
                
                // Create JavaScript string
                [results setObject:[NSString stringWithUTF8String:ip] atIndexedSubscript:n];
                n++;
            }
            
            // Increment
            address = address->ai_next;
        }
        
        [object invokeMethod:@"oncomplete" withArguments:@[[NSNumber numberWithInt:status], results]];
        
    } else {
        [object invokeMethod:@"oncomplete" withArguments:@[[NSNumber numberWithInt:status]]];
    }
    
    uv_freeaddrinfo(res);
    
    free(wrap);
}

@end
