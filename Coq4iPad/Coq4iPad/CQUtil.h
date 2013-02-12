//
//  CQUtil.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CQUtil : NSObject
+(NSString*)dirnameOf:(NSString*)path;
+(NSString*)basenameOf:(NSString*)path;
+(NSString*)fullPathOf:(NSString*)path;
+(NSString*)cacheDir;
+(NSString *)docDir;

// ダイアログを表示
+(void) showDialogWithMessage:(NSString*)message error:(NSError*)error;
// ダイアログを表示 (閉じた時のコールバック付き)
+(void) showDialogWithMessage:(NSString*)message error:(NSError*)error callback:(void(^)(void))callback;
// テキストボックス付きダイアログを表示 (閉じた時のコールバック付き, キャンセルの時nil)
+(void) showDialogWithMessage:(NSString*)message textboxWithString:(NSString*)text callback:(void(^)(NSString*))callback;
@end
