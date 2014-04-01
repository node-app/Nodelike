#import "NLTestCase.h"

@interface Console_Tests : NLTestCase

@end

@implementation Console_Tests : NLTestCase

- (void)testAll {
    [self runWithPrefix:@"test-console"];
}

@end
