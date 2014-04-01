//
//  NLContextify.h
//  Nodelike
//
//  Created by Sam Rijs on 2/2/14.
//  Copyright (c) 2014 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBinding.h"

@protocol NLContextifyExports <JSExport>

JSExportAs(runInContext, - (JSValue *)runInContext:(JSValue *)context options:(JSValue *)options);
- (JSValue *)runInThisContext:(JSValue *)options;
JSExportAs(runInNewContext, - (JSValue *)runInNewContext:(JSValue *)sandbox options:(JSValue *)options);

@end

@interface NLContextify : NLBinding <NLContextifyExports>

@property NSString *code;
@property JSValue  *options;

@end
