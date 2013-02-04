//
//  CQWrapper.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CQWrapper : NSObject
+(void) start;
+(void) parse:(NSMutableAttributedString*)str match:(void (^)(int, NSRange))match;
@end