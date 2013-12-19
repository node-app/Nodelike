//
//  NLStream.h
//  Nodelike
//
//  Created by Sam Rijs on 11/27/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLHandle.h"

struct NLStreamCallbacks {
    void (*doAlloc)(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf);
    void (*doRead)(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending);
};

@protocol NLStreamExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

- (NSNumber *)readStart;
- (NSNumber *)readStop;

@end

@interface NLStream : NLHandle <NLStreamExports>

- (id)initWithStream:(uv_stream_t *)stream inContext:(JSContext *)context;

@property uv_stream_t *stream;
@property struct NLStreamCallbacks *callbacks;

@end