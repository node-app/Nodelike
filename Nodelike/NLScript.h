//
//  NLScript.h
//  Nodelike
//
//  Created by Sam Rijs on 2/19/14.
//  Copyright (c) 2014 Sam Rijs. All rights reserved.
//

#import "NLBinding.h"

@protocol NLScriptExports <JSExport>

JSExportAs(runInContext, - (JSValue *)runInContext:(JSValue *)context options:(JSValue *)options);
- (JSValue *)runInThisContext:(JSValue *)options;
- (JSValue *)runInNewContext:(JSValue *)options;
- (JSValue *)createContext:(JSValue *)sandbox;

@end

@interface NLScript : NLBinding <NLScriptExports>

@property NSString *code;
@property JSValue  *options;

@end
