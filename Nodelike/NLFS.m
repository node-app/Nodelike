//
//  NLFS.m
//  Nodelike
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLFS.h"

#import "NLBuffer.h"

typedef void (*callback)(uv_fs_t *req);

static JSValue *Stats = nil;

@implementation NLFS

- (id)init {

    self = [super init];

    JSContext *context = JSContext.currentContext;
    
    Stats = [JSValue valueWithNewObjectInContext:context];
    Stats[@"prototype"] = [JSValue valueWithNewObjectInContext:context];

    return self;

}

- (JSValue *)Stats {
    return Stats;
}

+ (id)binding {
    return [self new];
}

#define call(fn, cb, then, ...) \
    do { \
        callback async; \
        uv_loop_t *loop = NLContext.eventLoop; \
        uv_fs_t *req = createReq(&async, cb, then); \
        uv_fs_ ## fn(loop, req, __VA_ARGS__, async); \
        return fireReq(req, async); \
    } while (0)

- (JSValue *)open:(longlived NSString *)path flags:(NSNumber *)flags mode:(NSNumber *)mode callback:(JSValue *)cb {
    call(open, cb, nil, path.UTF8String, flags.intValue, mode.intValue);
}

- (JSValue *)close:(NSNumber *)file callback:(JSValue *)cb {
    call(close, cb, nil, file.intValue);
}

- (JSValue *)read:(NSNumber *)file to:(JSValue *)target offset:(JSValue *)off length:(JSValue *)len pos:(JSValue *)pos callback:(JSValue *)cb {
    unsigned int buffer_length = [target[@"length"] toUInt32];
    unsigned int length   = [len isUndefined] ? buffer_length : [len toUInt32];
    unsigned int position = [pos isUndefined] ?             0 : [pos toUInt32];
    call(read, cb, ^(uv_fs_t *req) {
        [NLBuffer write:req->buf toBuffer:target atOffset:off withLength:len];
    }, file.intValue, malloc(length), length, position);
}

- (JSValue *)readDir:(longlived NSString *)path callback:(JSValue *)cb {
    call(readdir, cb, nil, path.UTF8String, 0);
}

- (JSValue *)fdatasync:(NSNumber *)file callback:(JSValue *)cb {
    call(fdatasync, cb, nil, file.intValue);
}

- (JSValue *)fsync:(NSNumber *)file callback:(JSValue *)cb {
    call(fsync, cb, nil, file.intValue);
}

- (JSValue *)rename:(longlived NSString *)oldpath to:(longlived NSString *)newpath callback:(JSValue *)cb {
    call(rename, cb, nil, oldpath.UTF8String, newpath.UTF8String);
}

- (JSValue *)ftruncate:(NSNumber *)file length:(NSNumber *)len callback:(JSValue *)cb {
    call(ftruncate, cb, nil, file.intValue, len.intValue);
}

- (JSValue *)rmdir:(longlived NSString *)path callback:(JSValue *)cb {
    call(rmdir, cb, nil, path.UTF8String);
}

- (JSValue *)mkdir:(longlived NSString *)path mode:(NSNumber *)mode callback:(JSValue *)cb {
    call(mkdir, cb, nil, path.UTF8String, mode.intValue);
}

- (JSValue *)link:(longlived NSString *)dst from:(longlived NSString *)src callback:(JSValue *)cb {
    call(link, cb, nil, dst.UTF8String, src.UTF8String);
}

- (JSValue *)symlink:(longlived NSString *)dst from:(longlived NSString *)src mode:(NSString *)mode callback:(JSValue *)cb {
    // we ignore the mode argument because it is only effective on windows platforms
    call(symlink, cb, nil, dst.UTF8String, src.UTF8String, 0 /*flags*/);
}

- (JSValue *)readlink:(longlived NSString *)path callback:(JSValue *)cb {
    call(readlink, cb, nil, path.UTF8String);
}

- (JSValue *)unlink:(longlived NSString *)path callback:(JSValue *)cb {
    call(unlink, cb, nil, path.UTF8String);
}

- (JSValue *)chmod:(longlived NSString *)path mode:(NSNumber *)mode callback:(JSValue *)cb {
    call(chmod, cb, nil, path.UTF8String, mode.intValue);
}

- (JSValue *)fchmod:(NSNumber *)file mode:(NSNumber *)mode callback:(JSValue *)cb {
    call(fchmod, cb, nil, file.intValue, mode.intValue);
}

- (JSValue *)chown:(longlived NSString *)path uid:(NSNumber *)uid gid:(NSNumber *)gid callback:(JSValue *)cb {
    call(chown, cb, nil, path.UTF8String, uid.unsignedIntValue, gid.unsignedIntValue);
}

- (JSValue *)fchown:(NSNumber *)file uid:(NSNumber *)uid gid:(NSNumber *)gid callback:(JSValue *)cb {
    call(fchown, cb, nil, file.intValue, uid.unsignedIntValue, gid.unsignedIntValue);
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
    call(stat, cb, nil, path.UTF8String);
}

- (JSValue *)lstat:(longlived NSString *)path callback:(JSValue *)cb {
    call(lstat, cb, nil, path.UTF8String);
}

- (JSValue *)fstat:(longlived NSNumber *)file callback:(JSValue *)cb {
    call(fstat, cb, nil, file.intValue);
}

struct data {
    void *callback, *error, *value, *after;
};

static JSContext *contextForEventRequest(uv_fs_t *req) {
    struct data *data = req->data;
    return (JSContext *)((__bridge JSValue *)data->callback).context;
}

static uv_fs_t *createReq(callback *async, JSValue *cb, void(^then)(uv_fs_t *)) {
    uv_fs_t *req = malloc(uv_req_size(UV_FS));
    struct data *data = req->data = malloc(sizeof(struct data));
    data->callback = (void *)CFBridgingRetain(cb);
    data->error = nil;
    data->value = nil;
    data->after = (void *)CFBridgingRetain(then);
    *async = cb.isUndefined ? nil : after;
    return req;
}

static JSValue *fireReq(uv_fs_t *req, callback async) {
    
    JSContext *context = JSContext.currentContext;
    
    struct data *data = req->data;
    
    if (!async) {
        
        after(req);
        
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
    JSValue *error = [JSValue valueWithNullInContext:context],
            *value = [JSValue valueWithUndefinedInContext:context];
    
    if (req->result < 0) {
        NSString *msg = [NSString stringWithUTF8String:uv_strerror((int)req->result)];
        error = [JSValue valueWithNewErrorFromMessage:msg inContext:context];
    } else {
        value = callSuccessfulEventRequest(req, value);
    }

    uv_fs_req_cleanup(req);
    
    JSValue *cb = CFBridgingRelease(data->callback);
    
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

static JSValue *callSuccessfulEventRequest(uv_fs_t *req, JSValue *nothing) {

    JSContext *context = contextForEventRequest(req);

    struct data *data = ((uv_req_t *)req)->data;
    if (data->after != nil) {
        ((void (^)(void *))CFBridgingRelease(data->after))(req);
    }

    switch (req->fs_type) {

        case UV_FS_CLOSE:
        case UV_FS_RENAME:
        case UV_FS_UNLINK:
        case UV_FS_RMDIR:
        case UV_FS_MKDIR:
        case UV_FS_FTRUNCATE:
        case UV_FS_FSYNC:
        case UV_FS_FDATASYNC:
        case UV_FS_LINK:
        case UV_FS_SYMLINK:
        case UV_FS_CHMOD:
        case UV_FS_FCHMOD:
        case UV_FS_CHOWN:
        case UV_FS_FCHOWN:
        case UV_FS_UTIME:
        case UV_FS_FUTIME:
            return nothing;

        case UV_FS_OPEN:
        case UV_FS_WRITE:
            return [JSValue valueWithInt32:(int)req->result inContext:context];

        case UV_FS_STAT:
        case UV_FS_LSTAT:
        case UV_FS_FSTAT:
            return buildStatsObject(req->ptr, Stats);

        case UV_FS_READLINK:
            return [JSValue valueWithObject:[NSString stringWithUTF8String:req->ptr] inContext:context];

        case UV_FS_READ:
            return [JSValue valueWithInt32:(int)req->result inContext:context];

        case UV_FS_READDIR: {
            char *namebuf = req->ptr;
            ssize_t i, nnames = req->result;
            JSValue *names = [JSValue valueWithNewArrayInContext:context];
            for (i = 0; i < nnames; i++) {
                names[i] = [NSString stringWithUTF8String:namebuf];
                namebuf += strlen(namebuf) + 1;
            }
            return names;
        }

        default:
            assert(0 && "Unhandled eio response");

    }

}

@end
