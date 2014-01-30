//
//  NLStream.m
//  Nodelike
//
//  Created by Sam Rijs on 11/27/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLStream.h"

#import "NLBuffer.h"
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
    defaultCallbacks.doWrite = doWrite;
    defaultCallbacks.afterWrite = afterWriteCallback;
    defaultCallbacks.doShutdown = doShutdown;
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

- (NSNumber *)writeObject:(JSValue *)obj withData:(const char *)data ofLength:(size_t)size forOptionalSendHandle:(NLHandle *)sendHandle {

    int err;
    
    if (size > INT_MAX) {
        return [NSNumber numberWithInt:UV_ENOBUFS];
    }

    struct writeWrap *writeWrap = malloc(sizeof(struct writeWrap));
    writeWrap->object = (void *)CFBridgingRetain(obj);
    writeWrap->wrap   = (__bridge void *)self;
    writeWrap->req.data = writeWrap;
    
    uv_buf_t buf;
    buf.base = memcpy(malloc(size), data, size);;
    buf.len  = size;
    
    if (!isNamedPipeIPC(_stream)) {
        err = _callbacks->doWrite(writeWrap, &buf, 1, NULL, afterWrite);
    } else {
        uv_handle_t* send_handle = NULL;
        if (sendHandle != nil) {
            send_handle = sendHandle.handle;
            [obj setValue:sendHandle forProperty:@"handle"];
        }
        err = _callbacks->doWrite(writeWrap, &buf, 1, (uv_stream_t *)send_handle, afterWrite);
    }
    
    [obj setValue:[NSNumber numberWithLong:size] forProperty:@"bytes"];
    
    if (err) {
        CFBridgingRelease(writeWrap->object);
        free(writeWrap);
    }

    return [NSNumber numberWithInt:err];
    
}

- (NSNumber *)writeObject:(JSValue *)obj withBuffer:(JSValue *)buffer forOptionalSendHandle:(NLHandle *)sendHandle {
    int len = [NLBuffer getLength:buffer];
    return [self writeObject:obj
                    withData:[NLBuffer getData:buffer ofSize:len]
                    ofLength:len
       forOptionalSendHandle:sendHandle];
}

- (NSNumber *)writeObject:(JSValue *)obj withAsciiString:(longlived NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle {
    return [self writeObject:obj
                    withData:[string cStringUsingEncoding:NSASCIIStringEncoding]
                    ofLength:[string lengthOfBytesUsingEncoding:NSASCIIStringEncoding]
       forOptionalSendHandle:sendHandle];
}

- (NSNumber *)writeObject:(JSValue *)obj withUtf8String:(longlived NSString *)string forOptionalSendHandle:(NLHandle *)sendHandle {
    return [self writeObject:obj
                    withData:[string cStringUsingEncoding:NSUTF8StringEncoding]
                    ofLength:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]
       forOptionalSendHandle:sendHandle];
}

- (NSNumber *)writeQueueSize {
    return [NSNumber numberWithLong:_stream->write_queue_size];
}

- (NSNumber *)shutdown:(JSValue *)obj {
    struct shutdownWrap *wrap = malloc(sizeof(struct shutdownWrap));
    wrap->wrap   = (__bridge void *)self;
    wrap->object = (void *)CFBridgingRetain(obj);
    wrap->req.data = wrap;
    int err = self.callbacks->doShutdown(wrap, afterShutdown);
    if (err) {
        CFBridgingRelease(wrap->object);
        free(wrap);
    }
    return [NSNumber numberWithInt:err];
}

static void onAlloc(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    NLStream *wrap = (__bridge NLStream *)handle->data;
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
    NLStream *wrap = (__bridge NLStream *)handle->data;
    wrap.callbacks->doRead(handle, nread, buf, pending);
}

static void doAlloc(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf) {
    buf->base = malloc(suggested_size);
    buf->len  = suggested_size;
}

static void doRead(uv_stream_t *handle, ssize_t nread, const uv_buf_t *buf, uv_handle_type pending) {

    NLHandle *wrap = (__bridge NLHandle *)(handle->data);

    NSMutableArray *args = [NSMutableArray arrayWithObject:[NSNumber numberWithLong:nread]];

    if (nread < 0)  {
        if (buf->base != NULL)
            free(buf->base);
        [wrap.object invokeMethod:@"onread" withArguments:args];
        return;
    }

    if (nread == 0) {
        if (buf->base != NULL)
            free(buf->base);
        return;
    }
    
    JSValue  *buffer      = [NLBuffer useData:buf->base ofLength:(int)nread inContext:wrap.object.context];
    NLStream *pending_obj = nil;

    [args addObject:buffer];
    
    if (pending == UV_TCP) {
        pending_obj = [[NLTCP alloc] initInContext:wrap.context];
    } else if (pending == UV_NAMED_PIPE) {
        pending_obj = nil; // TODO: implement pending named pipe
    } else if (pending == UV_UDP) {
        pending_obj = nil; // TODO: implement pending udp
    } else {
        assert(pending == UV_UNKNOWN_HANDLE);
    }
    
    if (pending_obj != nil) {
        [args addObject:pending_obj];
        if (uv_accept(handle, pending_obj.stream))
            abort();
    }
    
    [wrap.object invokeMethod:@"onread" withArguments:args];

}

static int doWrite(struct writeWrap* w, uv_buf_t* bufs, size_t count, uv_stream_t* send_handle, uv_write_cb cb) {
    
    NLStream *wrap = (__bridge NLStream *)w->wrap;
    
    int r;
    if (send_handle == NULL) {
        r = uv_write(&w->req, wrap.stream, bufs, (unsigned int)count, cb);
    } else {
        r = uv_write2(&w->req, wrap.stream, bufs, (unsigned int)count, send_handle, cb);
    }
    
    if (!r) {
        size_t bytes = 0;
        for (size_t i = 0; i < count; i++)
            bytes += bufs[i].len;
        if (wrap.stream->type == UV_TCP) {
            //NODE_COUNT_NET_BYTES_SENT(bytes);
        } else if (wrap.stream->type == UV_NAMED_PIPE) {
            //NODE_COUNT_PIPE_BYTES_SENT(bytes);
        }
    }

    return r;
}

static void afterWriteCallback(struct writeWrap *w) {
    return;
}

static void afterWrite(uv_write_t* req, int status) {
    struct writeWrap *reqWrap = req->data;
    NLStream *wrap   = (__bridge NLStream *)(reqWrap->wrap);
    JSValue  *object = (JSValue *)CFBridgingRelease(reqWrap->object);
    
    [object deleteProperty:@"handle"];
    wrap.callbacks->afterWrite(reqWrap);

    [object invokeMethod:@"oncomplete" withArguments:@[[NSNumber numberWithInt:status], wrap, object]];
    
    free(reqWrap);
}

int doShutdown(struct shutdownWrap* w, uv_shutdown_cb cb) {
    NLStream *wrap = (__bridge NLStream *)w->wrap;
    return uv_shutdown(&w->req, wrap.stream, cb);
}

void afterShutdown(uv_shutdown_t* req, int status) {
    struct shutdownWrap *shutdownWrap = req->data;
    NLStream *wrap   = (__bridge NLStream *)(shutdownWrap->wrap);
    JSValue  *object = (JSValue  *)CFBridgingRelease(shutdownWrap->object);
    [object invokeMethod:@"oncomplete" withArguments:@[[NSNumber numberWithInt:status], wrap, object]];
    free(shutdownWrap);
}

@end
