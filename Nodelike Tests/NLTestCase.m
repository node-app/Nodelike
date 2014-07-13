//
//  NLTestCase.m
//  Nodelike
//
//  Created by Sam Rijs on 3/8/14.
//  Copyright (c) 2014 Sam Rijs. All rights reserved.
//

#import "NLTestCase.h"

#import "NLContext.h"
#import "NLNatives.h"

@implementation NLTestCase

- (void)runWithPrefix:(NSString *)prefix {
	[self runWithPrefix:prefix skipping:nil];
}

- (void)runWithPrefix:(NSString *)prefix skipping:(NSArray *)bad {
    [NLNatives.modules enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
    if ([obj hasPrefix:prefix]) {
	    if ([bad containsObject:obj]) {
		    NSLog(@"skipping %@", obj);
		    return;
	    }
            NSLog(@"running %@", obj);
            NLContext *ctx = [NLContext new];
            [ctx evaluateScript:@"require_ = require; require = (function (module) { return require_(module.substr(0,9) === '../common' ? 'test-common' : module); });"];
            [ctx evaluateScript:[NLNatives source:obj]];
            JSValue *e = ctx.exception;
            if (e)
                XCTFail(@"%@: Context exception thrown: %@; stack: %@", obj, e, [e valueForProperty:@"stack"]);
            [NLContext runEventLoopSyncInContext:ctx];
            [ctx emitExit];
            [NLContext runEventLoopSyncInContext:ctx];
        }
    }];
}

+ (void)tearDown {
    [super tearDown];
    // flush coverage data
    extern void __gcov_flush(void);
    __gcov_flush();
}

@end
