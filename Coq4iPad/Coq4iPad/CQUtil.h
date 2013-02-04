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
@end
