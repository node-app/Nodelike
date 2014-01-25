//
//  NLFS.h
//  Nodelike
//
//  Created by Sam Rijs on 10/13/13.
//  Copyright (c) 2013 Sam Rijs.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "NLBinding.h"

@protocol NLFSExports <JSExport>

@property (readonly) JSValue *Stats;

JSExportAs(open,  - (JSValue *)open:(NSString *)path flags:(NSNumber *)flags mode:(NSNumber *)mode callback:(JSValue *)cb);
JSExportAs(close, - (JSValue *)close:(NSNumber *)file callback:(JSValue *)cb);

JSExportAs(read, - (JSValue *)read:(NSNumber *)file to:(JSValue *)target offset:(JSValue *)off length:(JSValue *)len pos:(JSValue *)pos callback:(JSValue *)cb);

JSExportAs(readdir, - (JSValue *)readDir:(NSString *)path callback:(JSValue *)cb);

JSExportAs(fdatasync, - (JSValue *)fdatasync:(NSNumber *)file callback:(JSValue *)cb);
JSExportAs(fsync,     - (JSValue *)fsync:    (NSNumber *)file callback:(JSValue *)cb);

JSExportAs(rename, - (JSValue *)rename:(NSString *)oldpath to:(NSString *)newpath callback:(JSValue *)cb);

JSExportAs(ftruncate, - (JSValue *)ftruncate:(NSNumber *)file length:(NSNumber *)len callback:(JSValue *)cb);

JSExportAs(rmdir, - (JSValue *)rmdir:(NSString *)path callback:(JSValue *)cb);

JSExportAs(mkdir, - (JSValue *)mkdir:(NSString *)path mode:(NSNumber *)mode callback:(JSValue *)cb);

JSExportAs(link,    - (JSValue *)link:   (NSString *)dstpath from:(NSString *)srcpath                       callback:(JSValue *)cb);
JSExportAs(symlink, - (JSValue *)symlink:(NSString *)dstpath from:(NSString *)srcpath mode:(NSString *)mode callback:(JSValue *)cb);

JSExportAs(readlink, - (JSValue *)readlink:(NSString *)path callback:(JSValue *)cb);

JSExportAs(unlink, - (JSValue *)unlink:(NSString *)path callback:(JSValue *)cb);

JSExportAs(chmod,  - (JSValue *)chmod: (NSString *)path mode:(NSNumber *)mode callback:(JSValue *)cb);
JSExportAs(fchmod, - (JSValue *)fchmod:(NSNumber *)file mode:(NSNumber *)mode callback:(JSValue *)cb);

JSExportAs(chown,  - (JSValue *)chown: (NSString *)path uid:(NSNumber *)uid gid:(NSNumber *)gid callback:(JSValue *)cb);
JSExportAs(fchown, - (JSValue *)fchown:(NSNumber *)file uid:(NSNumber *)uid gid:(NSNumber *)gid callback:(JSValue *)cb);

JSExportAs(stat,  - (JSValue *)stat: (NSString *)path callback:(JSValue *)cb);
JSExportAs(lstat, - (JSValue *)lstat:(NSString *)path callback:(JSValue *)cb);
JSExportAs(fstat, - (JSValue *)fstat:(NSNumber *)file callback:(JSValue *)cb);

@end

@interface NLFS : NLBinding <NLFSExports>

@property (readonly) JSValue *Stats;

@end
