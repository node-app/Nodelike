#import "NLTestCase.h"

@interface Read_Tests : NLTestCase

@end

@implementation Read_Tests : NLTestCase

- (void)testAll {
    [self runWithPrefix:@"test-readint"];
    [self runWithPrefix:@"test-readuint"];
    [self runWithPrefix:@"test-readdouble"];
    [self runWithPrefix:@"test-readfloat"];
}

@end
