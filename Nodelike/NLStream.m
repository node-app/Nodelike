//
//  NLStream.m
//  Nodelike
//
//  Created by Sam Rijs on 11/27/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLStream.h"

#import "NLBindingBuffer.h"
#import "NLTCP.h"

@implementation NLStream {
    struct NLStreamCallbacks defaultCallbacks;
}

#define isNamedPipe(stream)    (stream->type == UV_NAMED_PIPE)
#define isNamedPipeIPC(stream) (isNamedPipe(stream) && ((uv_pipe_t *)stream)->ipc != 0)
#define isTCP(stream)          (stream->type == UV_TCP)

- (id)initWithStream:(uv_stream_t *)stream inContext:(JSContext *)context {
    self = [super initWithHandle:(uv_handle_t *)stream inContext:context];
    _stream = stream;
    defaultCallbacks.doAlloc = doAlloc;
    defaultCallbacks.doRead  = doRead;
    _callbacks = &defaultCallbacks;
    return self;
}

- (NSNumber *)readStart {
    int err;
    if (isNamedPipeIPC(_stream)) {
        err = uv_read2_start(_stream, onAlloc, onRead2);
    } else {
        err = uv_read_start(_stream, onAlloc, onRead);
    }
    return [NSNumber numberWithInt:err];
}

- (NSNumber *)readStop {
    return [NSNumber numberWithInt:uv_read_stop(_stream)];
}

static void onAlloc(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    NLStream *wrap = [(__bridge JSValue *)(handle->data) toObjectOfClass:NLStream.class];
    assert(wrap.stream == (uv_stream_t *)handle);
    wrap.callbacks->doAlloc(handle, suggested_size, buf);
}

static void onRead(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf) {
    onReadCommon(handle, nread, buf, UV_UNKNOWN_HANDLE);
}

static void onRead2(uv_pipe_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending) {
    onReadCommon((uv_stream_t *)handle, nread, buf, pending);
}

static void onReadCommon(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending) {
    NLStream *wrap = [(__bridge JSValue *)(handle->data) toObjectOfClass:NLStream.class];
    wrap.callbacks->doRead(handle, nread, buf, pending);
}

static void doAlloc(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf) {
    buf->base = malloc(suggested_size);
    buf->len  = suggested_size;
}

static void doRead(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending) {

    JSValue *value = (__bridge JSValue *)(handle->data);

    if (nread < 0)  {
        if (buf->base != NULL)
            free(buf->base);
        [value invokeMethod:@"onread" withArguments:@[[NSNumber numberWithLong:nread]]];
        return;
    }

    if (nread == 0) {
        if (buf->base != NULL)
            free(buf->base);
        return;
    }

    JSValue  *buffer      = [NLBindingBuffer useData:buf->base ofLength:buf->len];
    NLStream *pending_obj = nil;
    
    if (pending == UV_TCP) {
        pending_obj = [NLTCP new];
    } else if (pending == UV_NAMED_PIPE) {
        pending_obj = nil; // TODO: implement pending named pipe
    } else if (pending == UV_UDP) {
        pending_obj = nil; // TODO: implement pending udp
    } else {
        assert(pending == UV_UNKNOWN_HANDLE);
    }
    
    if (pending_obj != nil) {
        if (uv_accept(handle, pending_obj.stream))
            abort();
    }
    
    [value invokeMethod:@"onread" withArguments:@[[NSNumber numberWithLong:nread], buffer, pending_obj]];

}


@end
