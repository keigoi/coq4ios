//
//  CQWrapper.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CQWrapperDelegate <NSObject>
-(void)enterBusy;
-(void)exitBusy;
@end

@interface CQWrapper : NSObject
// Coq functions in main.ml
+(BOOL) isReady;
+(void) startRuntime;
+(void) startCoq:(NSString*)coqlib callback:(void(^)(BOOL))callback;
+(NSArray*) libraryTheories;
+(void) compile:(NSString*)file callback:(void(^)())callback;
+(void) parse:(const char*)str match:(void (^)(int, NSRange))match;
+(void) eval:(NSString*)str callback:(void(^)(BOOL, NSString*))callback;
+(NSRange) nextPhraseRange:(NSString*)text;
+(void) rewind:(void(^)(int extra))callback;
+(void) resetInitial:(void(^)())callback;
+(void) stop;
// utility methods
+(void) runInQueue:(void(^)())callback;
+(void) setDelegate:(id<CQWrapperDelegate>)delegate;
@end