//
//  NLTimer_Tests.m
//  Nodelike
//
//  Created by Sam Rijs on 1/25/14.
//  Copyright (c) 2014 Sam Rijs. All rights reserved.
//

#import "NLTestCase.h"

#import "NLContext.h"

@interface NLTimer_Tests : NLTestCase

@end

@implementation NLTimer_Tests

- (void)testTimer {
    [self runWithPrefix:@"test-timers"];
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
    [NLContext runEventLoopAsyncInContext:ctx];
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
    [NLContext runEventLoopAsyncInContext:ctx];
    XCTAssertFalse(canary, @"Canary not false immediately after timeout set.");
    [NSThread sleepForTimeInterval:1.1f];
    XCTAssertTrue(canary, @"Canary not true immediately after timeout fired.");
}

@end
