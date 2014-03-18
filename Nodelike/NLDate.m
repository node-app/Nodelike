#import "NLDate.h"

@implementation NLDate {
}

+ (id)binding {
    JSValue   *date     = self.constructor;
    return @{@"Date": date};
}

- (id)init {
    self = [super init];
    return self;
}

@end
