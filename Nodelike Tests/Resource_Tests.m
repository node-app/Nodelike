//
//  Resource_Tests.m
//  Nodelike
//
//  Created by Sam Rijs on 2/27/14.
//  Copyright (c) 2014 Sam Rijs. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NLContext.h"

@interface Resource_Tests : XCTestCase

@end

@implementation Resource_Tests

- (void)testResourcePathIsSet {
    NLContext *ctx = [NLContext new];
    ctx.exceptionHandler = ^(JSContext *ctx, JSValue *e) {
        XCTFail(@"Context exception thrown: %@; stack: %@", e, [e valueForProperty:@"stack"]);
    };
    JSValue *pv = [ctx evaluateScript:@"process.resourcePath"];
    XCTAssertTrue(pv.isString, @"resource path is not a string.");
    NSLog(@"resourcePath=%@", pv.toString);
}

@end
