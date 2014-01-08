//
//  NLStream.h
//  Nodelike
//
//  Created by Sam Rijs on 11/27/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLHandle.h"

typedef struct writeWrap {
    uv_write_t req;
    void      *wrap;
    void      *object;
} writeWrap;

struct shutdownWrap {
    uv_shutdown_t req;
    void         *wrap;
    void         *object;
};

struct NLStreamCallbacks {
    void (*doAlloc)(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf);
    void (*doRead)(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending);
    int  (*doWrite)(struct writeWrap* w, uv_buf_t* bufs, size_t count, uv_stream_t* send_handle, uv_write_cb cb);
    void (*afterWrite)(struct writeWrap *w);
    int  (*doShutdown)(struct shutdownWrap* wrap, uv_shutdown_cb cb);
};

@protocol NLStreamExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

- (NSNumber *)readStart;
- (NSNumber *)readStop;

@property (readonly) NSNumber *writeQueueSize;

JSExportAs(writeAsciiString, - (NSNumber *)writeObject:(JSValue *)obj withAsciiString:(NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle);
JSExportAs(writeUtf8String,  - (NSNumber *)writeObject:(JSValue *)obj withUtf8String:(NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle);
JSExportAs(writeBuffer,      - (NSNumber *)writeObject:(JSValue *)obj withBuffer:(JSValue *)buffer forOptionalSendHandle:(NLHandle *)sendHandle);

- (NSNumber *)shutdown:(JSValue *)obj;

@end

@interface NLStream : NLHandle <NLStreamExports>

- (id)initWithStream:(uv_stream_t *)stream inContext:(JSContext *)context;

- (NSNumber *)writeObject:(JSValue *)obj withData:(const char *)data ofLength:(size_t)size forOptionalSendHandle:(NLHandle *)sendHandle;

@property uv_stream_t *stream;
@property struct NLStreamCallbacks *callbacks;

@property (readonly) NSNumber *writeQueueSize;

@end