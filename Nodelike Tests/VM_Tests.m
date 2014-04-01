//
//  VM_Tests.m
//  Nodelike
//
//  Created by Sam Rijs on 2/19/14.
//  Copyright (c) 2014 Sam Rijs. All rights reserved.
//

#import "NLTestCase.h"

@interface VM_Tests : NLTestCase

@end

@implementation VM_Tests

- (void)testAll {
    NSMutableArray * bad = [NSMutableArray new];
#if !USE_PRIVATE_APIS
    [bad addObject:@"test-vm-timeout"];
#endif
    [self runWithPrefix:@"test-vm" skipping:bad];
}

@end
