#import "NLTTY.h"

@implementation NLTTY {
    uv_tty_t handle;
}

+ (id)binding {
	return @{
		@"TTY": [NLBinding makeConstructor:^(NSNumber *fd, NSNumber *readable) {
				NLTTY *tty = [NLTTY new];
				[tty TTY:fd readable:readable];
				return tty;
			} inContext:JSContext.currentContext],
		@"guessHandleType": ^(NSNumber *fd){ return @"TTY"; },
		};
}

- (id)init {
    return [self initInContext:JSContext.currentContext];
}

- (id)initInContext:(JSContext *)context {
    self = [super initWithStream:(uv_stream_t *)&handle inContext:context];
    return self;
}

- (void)TTY:(NSNumber *)fd readable:(NSNumber *)readable {
    int r = uv_tty_init(NLContext.eventLoop, &handle, fd.intValue, readable.intValue);
    assert(r == 0);
}

- (JSValue *)getWindowSize:(JSValue *)size {
    return [JSValue valueWithNewErrorFromMessage:@"unimplemented" inContext:JSContext.currentContext];
}

@end
