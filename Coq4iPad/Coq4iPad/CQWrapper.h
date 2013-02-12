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
+(NSArray*) initTheories;
+(NSArray*) restTheories;
+(void) compile:(NSString*)file callback:(void(^)())callback;
+(void) parse:(const char*)str match:(void (^)(int, NSRange))match;
+(void) eval:(const char*)str;
@end