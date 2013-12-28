//
//  NLBindingFilesystem.m
//  NodelikeDemo
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs. All rights reserved.
//

#import "NLBindingFilesystem.h"

#import "NLBindingBuffer.h"

@implementation NLBindingFilesystem

- (id)init {

    self = [super init];

    JSContext *context = JSContext.currentContext;
    
    _Stats = [JSValue valueWithNewObjectInContext:context];
    _Stats[@"prototype"] = [JSValue valueWithNewObjectInContext:context];

    return self;

}

+ (id)binding {
    return [self new];
}

- (JSValue *)open:(longlived NSString *)path flags:(NSNumber *)flags mode:(NSNumber *)mode callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_open(loop, req, path.UTF8String, flags.intValue, mode.intValue, async ? after : nil);
    }, ^(uv_fs_t *req, JSContext *context) {
        setValue([JSValue valueWithInt32:(int)req->result inContext:context], req);
    });
}

- (JSValue *)close:(NSNumber *)file callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_close(loop, req, file.intValue, async ? after : nil);
    }, nil);
}

- (JSValue *)read:(NSNumber *)file to:(JSValue *)target offset:(JSValue *)off length:(JSValue *)len pos:(JSValue *)pos callback:(JSValue *)cb {
    unsigned int buffer_length = [target[@"length"] toUInt32];
    unsigned int length   = [len isUndefined] ? buffer_length : [len toUInt32];
    unsigned int position = [pos isUndefined] ?             0 : [pos toUInt32];
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_read(loop, req, file.intValue, malloc(length), length, position, async ? after : nil);
    }, ^(uv_fs_t *req, JSContext *context) {
        [NLBindingBuffer write:req->buf toBuffer:target atOffset:off withLength:len];
        setValue([JSValue valueWithInt32:(int)req->result inContext:context], req);
    });
}

- (JSValue *)readDir:(longlived NSString *)path callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_readdir(loop, req, path.UTF8String, 0, async ? after : nil);
    }, ^(uv_fs_t *req, JSContext *context) {
        char *namebuf = req->ptr;
        ssize_t i, nnames = req->result;
        JSValue *names = [JSValue valueWithNewArrayInContext:context];
        for (i = 0; i < nnames; i++) {
            names[i] = [NSString stringWithUTF8String:namebuf];
            namebuf += strlen(namebuf) + 1;
        }
        setValue(names, req);
    });
}

- (JSValue *)fdatasync:(NSNumber *)file callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_fdatasync(loop, req, file.intValue, async ? after : nil);
    }, nil);
}

- (JSValue *)fsync:(NSNumber *)file callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_fsync(loop, req, file.intValue, async ? after : nil);
    }, nil);
}

- (JSValue *)rename:(longlived NSString *)oldpath to:(longlived NSString *)newpath callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_rename(loop, req, oldpath.UTF8String, newpath.UTF8String, async ? after : nil);
    }, nil);
}

- (JSValue *)ftruncate:(NSNumber *)file length:(NSNumber *)len callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_ftruncate(loop, req, file.intValue, len.intValue, async ? after : nil);
    }, nil);
}

- (JSValue *)rmdir:(longlived NSString *)path callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_rmdir(loop, req, path.UTF8String, async ? after : nil);
    }, nil);
}

- (JSValue *)mkdir:(longlived NSString *)path mode:(NSNumber *)mode callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_mkdir(loop, req, path.UTF8String, mode.intValue, async ? after : nil);
    }, nil);
}

- (JSValue *)link:(longlived NSString *)dst from:(longlived NSString *)src callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_link(loop, req, dst.UTF8String, src.UTF8String, async ? after : nil);
    }, nil);
}

- (JSValue *)symlink:(longlived NSString *)dst from:(longlived NSString *)src mode:(NSString *)mode callback:(JSValue *)cb {
    // we ignore the mode argument because it is only effective on windows platforms
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_symlink(loop, req, dst.UTF8String, src.UTF8String, 0 /*flags*/, async ? after : nil);
    }, nil);
}

- (JSValue *)readlink:(longlived NSString *)path callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_readlink(loop, req, path.UTF8String, async ? after : nil);
    }, ^(uv_fs_t *req, JSContext *context) {
        NSString *str = [NSString stringWithUTF8String:req->ptr];
        setValue([JSValue valueWithObject:str inContext:context], req);
    });
}

- (JSValue *)unlink:(longlived NSString *)path callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_unlink(loop, req, path.UTF8String, async ? after : nil);
    }, nil);
}

- (JSValue *)chmod:(longlived NSString *)path mode:(NSNumber *)mode callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_chmod(loop, req, path.UTF8String, mode.intValue, async ? after : nil);
    }, nil);
}

- (JSValue *)fchmod:(NSNumber *)file mode:(NSNumber *)mode callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_fchmod(loop, req, file.intValue, mode.intValue, async ? after : nil);
    }, nil);
}

- (JSValue *)chown:(longlived NSString *)path uid:(NSNumber *)uid gid:(NSNumber *)gid callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_chown(loop, req, path.UTF8String, uid.unsignedIntValue, gid.unsignedIntValue, async ? after : nil);
    }, nil);
}

- (JSValue *)fchown:(NSNumber *)file uid:(NSNumber *)uid gid:(NSNumber *)gid callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_fchown(loop, req, file.intValue, uid.unsignedIntValue, gid.unsignedIntValue, async ? after : nil);
    }, nil);
}

#pragma mark stat

const static JSObjectRef spec_to_date(uv_timespec_t spec, JSContextRef ctx) {
    JSValueRef val = JSValueMakeNumber(ctx, ((double)spec.tv_sec) * 1000 + ((double)spec.tv_nsec) / 1000 / 1000);
    return JSObjectMakeDate(ctx, 1, &val, nil);
}

static JSValue *buildStatsObject(const uv_stat_t *s, JSValue *_Stats) {
    JSContext   *context    = _Stats.context;
    JSContextRef contextRef = context.JSGlobalContextRef;
    JSValue     *stats      = [JSValue valueWithNewObjectInContext:context];
    stats[@"__proto__"] = _Stats[@"prototype"];
    stats[@"dev"]       = [JSValue valueWithInt32:s->st_dev    inContext:context];
    stats[@"mode"]      = [JSValue valueWithInt32:s->st_mode   inContext:context];
    stats[@"nlink"]     = [JSValue valueWithInt32:s->st_nlink  inContext:context];
    stats[@"uid"]       = [JSValue valueWithInt32:s->st_uid    inContext:context];
    stats[@"gid"]       = [JSValue valueWithInt32:s->st_gid    inContext:context];
    stats[@"rdev"]      = [JSValue valueWithInt32:s->st_rdev   inContext:context];
    stats[@"ino"]       = [JSValue valueWithInt32:s->st_ino    inContext:context];
    stats[@"size"]      = [JSValue valueWithInt32:s->st_size   inContext:context];
    stats[@"blocks"]    = [JSValue valueWithInt32:s->st_blocks inContext:context];
    stats[@"atime"]     = [JSValue valueWithJSValueRef:spec_to_date(s->st_atim,     contextRef) inContext:context];
    stats[@"mtime"]     = [JSValue valueWithJSValueRef:spec_to_date(s->st_mtim,     contextRef) inContext:context];
    stats[@"ctime"]     = [JSValue valueWithJSValueRef:spec_to_date(s->st_ctim,     contextRef) inContext:context];
    stats[@"birthtime"] = [JSValue valueWithJSValueRef:spec_to_date(s->st_birthtim, contextRef) inContext:context];
    return stats;
}

- (JSValue *)stat:(longlived NSString *)path callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_stat(loop, req, path.UTF8String, async ? after : nil);
    }, ^(uv_fs_t *req, JSContext *context) {
        setValue(buildStatsObject(req->ptr, _Stats), req);
    });
}

- (JSValue *)lstat:(longlived NSString *)path callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_lstat(loop, req, path.UTF8String, async ? after : nil);
    }, ^(uv_fs_t *req, JSContext *context) {
        setValue(buildStatsObject(req->ptr, _Stats), req);
    });
}

- (JSValue *)fstat:(longlived NSNumber *)file callback:(JSValue *)cb {
    return createEventRequest(cb, ^(uv_loop_t *loop, uv_fs_t *req, bool async) {
        uv_fs_fstat(loop, req, file.intValue, async ? after : nil);
    }, ^(uv_fs_t *req, JSContext *context) {
        setValue(buildStatsObject(req->ptr, _Stats), req);
    });
}

struct data {
    void *callback, *error, *value, *after;
};

static JSContext *contextForEventRequest(uv_fs_t *req) {
    struct data *data = req->data;
    return (JSContext *)((__bridge JSValue *)data->callback).context;
}

static JSValue *createEventRequest(JSValue *cb,
                                   void(^task)(uv_loop_t *, uv_fs_t *, bool),
                                   void(^after)(uv_fs_t *, JSContext *)) {
    
    JSContext *context = JSContext.currentContext;
    
    uv_fs_t *req = malloc(uv_req_size(UV_FS));
    
    struct data *data = req->data = malloc(sizeof(struct data));
    data->callback = (void *)CFBridgingRetain(cb);
    data->error = nil;
    data->value = nil;
    data->after = (void *)CFBridgingRetain(after);
    
    bool async = ![cb isUndefined];
    
    task(NLContext.eventLoop, req, async);
    
    if (!async) {
        
        JSValue *error = data->error != nil ? CFBridgingRelease(data->error) : nil;
        JSValue *value = data->value != nil ? CFBridgingRelease(data->value) : nil;
        
        free(data);
        
        if (error == nil) {
            return value;
        } else {
            context.exception = error;
        }
        
    }
    
    return nil;
    
}

static void after(uv_fs_t *req) {
    
    JSContext *context = contextForEventRequest(req);
    
    struct data *data = req->data;
    
    if (req->result < 0) {
        setErrorCode((int)req->result, req);
    } else {
        callSuccessfulEventRequest(req);
    }
    uv_fs_req_cleanup(req);
    
    JSValue *cb    = CFBridgingRelease(data->callback);
    JSValue *error = data->error != nil ? CFBridgingRelease(data->error) : [JSValue valueWithNullInContext:context];
    JSValue *value = data->value != nil ? CFBridgingRelease(data->value) : [JSValue valueWithUndefinedInContext:context];
    
    if (![cb isUndefined]) {
        
        free(data);
        [cb callWithArguments:@[error, value]];
        
    } else if ([error isNull]) {
        
        data->error = nil;
        data->value = (void *)CFBridgingRetain(value);
        
    } else {
        
        data->error = (void *)CFBridgingRetain(error);
        data->value = nil;
        
    }
    
}

static void callSuccessfulEventRequest(void *req) {
    JSContext *context = contextForEventRequest(req);
    struct data *data = ((uv_req_t *)req)->data;
    if (data->after != nil) {
        ((void (^)(void*, JSContext *))CFBridgingRelease(data->after))(req, context);
    }
}

static void setErrorCode(int error, void *req) {
    JSContext *context = contextForEventRequest(req);
    NSString *msg = [NSString stringWithUTF8String:uv_strerror(error)];
    setError([JSValue valueWithNewErrorFromMessage:msg inContext:context], req);
}

static void setError(JSValue *error, void *req) {
    ((struct data *)(((uv_req_t *)req)->data))->error = (void *)CFBridgingRetain(error);
}

static void setValue(JSValue *value, void *req) {
    ((struct data *)(((uv_req_t *)req)->data))->value = (void *)CFBridgingRetain(value);
}

@end
