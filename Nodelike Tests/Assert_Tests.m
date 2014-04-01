#import "NLTestCase.h"

@interface Assert_Tests : NLTestCase

@end

@implementation Assert_Tests : NLTestCase

- (void)testAll {
    [self runWithPrefix:@"test-assert"];
}

@end
