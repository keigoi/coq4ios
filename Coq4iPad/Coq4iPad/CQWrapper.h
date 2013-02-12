//
//  CQWrapper.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CQWrapper : NSObject
+(void) startRuntime;
+(void) startCoq:(NSString*)coqlib callback:(void(^)())callback;
+(void) loadInitial;
+(NSArray*) libraryTheories;
+(void) compile:(NSString*)file callback:(void(^)())callback;
+(void) parse:(const char*)str match:(void (^)(int, NSRange))match;
+(void) eval:(NSString*)str_ callback:(void(^)(NSString*))callback;
+(void) reset;
+(void) stop;
+(void) undo;
+(NSRange) nextPhraseRange:(NSString*)text;
@end