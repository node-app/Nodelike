//
//  NLStream.h
//  Nodelike
//
//  Created by Sam Rijs on 11/27/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLHandle.h"

typedef struct writeWrap {
    uv_write_t req;
    void      *wrap;
    void      *object;
} writeWrap;

struct NLStreamCallbacks {
    void (*doAlloc)(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf);
    void (*doRead)(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending);
    int  (*doWrite)(struct writeWrap* w, uv_buf_t* bufs, size_t count, uv_stream_t* send_handle, uv_write_cb cb);
    void (*afterWrite)(struct writeWrap *w);
};

@protocol NLStreamExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

- (NSNumber *)readStart;
- (NSNumber *)readStop;

@property NSNumber *writeQueueSize;

JSExportAs(writeAsciiString, - (NSNumber *)writeObject:(JSValue *)obj withAsciiString:(NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle);
JSExportAs(writeUtf8String,  - (NSNumber *)writeObject:(JSValue *)obj withUtf8String:(NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle);

@end

@interface NLStream : NLHandle <NLStreamExports>

- (id)initWithStream:(uv_stream_t *)stream inContext:(JSContext *)context;

- (NSNumber *)writeObject:(JSValue *)obj withString:(NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle;
- (NSNumber *)writeObject:(JSValue *)obj withAsciiString:(NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle;
- (NSNumber *)writeObject:(JSValue *)obj withUtf8String:(NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle;

@property uv_stream_t *stream;
@property struct NLStreamCallbacks *callbacks;

@property NSNumber *writeQueueSize;

@end