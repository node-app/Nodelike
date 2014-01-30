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

- (void)testSetTimeout0 {
    __block bool canary = false;
    NLContext *ctx = [NLContext new];
    ctx.exceptionHandler = ^(JSContext *ctx, JSValue *e) {
        XCTFail(@"Context exception thrown: %@", e);
    };
    ctx[@"callback"] = ^{
        canary = true;
    };
    [ctx evaluateScript:@"require('timers').setTimeout(callback, 0);"];
    [NLContext runEventLoopAsync];
    [NSThread sleepForTimeInterval:0.1f];
    XCTAssertTrue(canary, @"Canary not true immediately after timeout fired.");
}

- (void)testSetTimeout1000 {
    __block bool canary = false;
    NLContext *ctx = [NLContext new];
    ctx.exceptionHandler = ^(JSContext *ctx, JSValue *e) {
        XCTFail(@"Context exception thrown: %@", e);
    };
    ctx[@"callback"] = ^{
        canary = true;
    };
    [ctx evaluateScript:@"require('timers').setTimeout(callback, 1000);"];
    [NLContext runEventLoopAsync];
    XCTAssertFalse(canary, @"Canary not false immediately after timeout set.");
    [NSThread sleepForTimeInterval:1.1f];
    XCTAssertTrue(canary, @"Canary not true immediately after timeout fired.");
}

@end
