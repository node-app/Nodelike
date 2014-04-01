#import "NLStream.h"

@protocol NLTTYExports <JSExport>

- (void)ref;
- (void)unref;
- (void)close:(JSValue *)cb;

- (NSNumber *)readStart;
- (NSNumber *)readStop;

- (JSValue *)getWindowSize:(JSValue *)size;
@end

@interface NLTTY : NLStream <NLTTYExports>

- (id)initInContext:(JSContext *)context;

@end
