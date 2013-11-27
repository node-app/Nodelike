//
//  NLStream.m
//  Nodelike
//
//  Created by Sam Rijs on 11/27/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLStream.h"

@implementation NLStream {
    uv_stream_t *stream;
}

#define isNamedPipe(stream)    (stream->type == UV_NAMED_PIPE)
#define isNamedPipeIPC(stream) (isNamedPipe(stream) && ((uv_pipe_t *)stream)->ipc != 0)
#define isTCP(stream)          (stream->type == UV_TCP)

- (NSNumber *)readStart {
    int err;
    if (isNamedPipeIPC(stream)) {
        err = uv_read2_start(stream, onAlloc, onRead2);
    } else {
        err = uv_read_start(stream, onAlloc, onRead);
    }
    return [NSNumber numberWithInt:err];
}

static void onAlloc(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    return;
}

static void onRead(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf) {
    onReadCommon(handle, nread, buf, UV_UNKNOWN_HANDLE);
}

static void onRead2(uv_pipe_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending) {
    onReadCommon((uv_stream_t *)handle, nread, buf, pending);
}

static void onReadCommon(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending) {
    return;
}



@end
