//
//  NLTimer_Tests.m
//  Nodelike
//
//  Created by Sam Rijs on 1/25/14.
//  Copyright (c) 2014 Sam Rijs. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NLContext.h"

@interface NLTimer_Tests : XCTestCase

@end

@implementation NLTimer_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testBundle {
    NSString *path = [NSBundle.mainBundle pathForResource:@"timers" ofType:@"js"];
    XCTAssertNotNil(path, @"Bundle returns no path for resource.");
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:path], @"Bundle file does not exist at path: %@", path);
}

- (void)testSetTimeout {
    __block bool canary = false;
    NLContext *ctx = [NLContext new];
    ctx[@"callback"] = ^{
        canary = true;
    };
    ctx.exceptionHandler = ^(JSContext *ctx, JSValue *e) {
        XCTFail(@"Context exception thrown: %@", e);
    };
    [ctx evaluateScript:@"require('timers').setTimeout(callback, 1000);"];
    XCTAssertFalse(canary, @"Canary not false immediately after timeout set.");
    [NSThread sleepForTimeInterval:1.0f];
    XCTAssertFalse(canary, @"Canary not false immediately after timeout fired.");
}

@end
