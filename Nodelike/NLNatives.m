//
//  NLNatives.m
//  Nodelike
//
//  Created by Sam Rijs on 1/25/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLNatives.h"

@implementation NLNatives

+ (NSArray *)moduleNames {
    return @[
             @"_debugger",
             @"_http_agent",
             @"_http_client",
             @"_http_common",
             @"_http_incoming",
             @"_http_outgoing",
             @"_http_server",
             @"_linklist",
             @"_stream_duplex",
             @"_stream_passthrough",
             @"_stream_readable",
             @"_stream_transform",
             @"_stream_writable",
             @"_tls_legacy",
             @"_tls_wrap",
             @"assert",
             @"buffer",
             @"child_process",
             @"cluster",
             @"console",
             @"constants",
             @"crypto",
             @"dgram",
             @"dns",
             @"domain",
             @"events",
             @"freelist",
             @"fs",
             @"http",
             @"https",
             @"module",
             @"net",
             @"os",
             @"path",
             @"punycode",
             @"querystring",
             @"readline",
             @"repl",
             @"smalloc",
             @"stream",
             @"string_decoder",
             @"sys",
             @"timers",
             @"tls",
             @"tty",
             @"url",
             @"util",
             @"vm",
             @"zlib"
             ];
}

+ (NSString *)source:(NSString *)module {
    NSBundle *bundle     = [NSBundle bundleForClass:self.class];
    NSString *bundlePath = [bundle pathForResource:@"Nodelike" ofType:@"bundle"];
    if (bundlePath) {
        bundle = [NSBundle bundleWithPath:bundlePath];
    }
    NSString *path    = [bundle pathForResource:module ofType:@"js"];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    return content;
}

+ (id)binding {
    NSArray  *names = self.moduleNames;
    NSString *name;
    JSValue  *sources = [JSValue valueWithNewObjectInContext:JSContext.currentContext];
    for (int i = 0; i < names.count; i++) {
        name = names[i];
        [sources defineProperty:name
                     descriptor:@{JSPropertyDescriptorGetKey: ^{ return [NLNatives source:name]; }}];
    }
    return sources;
}

@end
