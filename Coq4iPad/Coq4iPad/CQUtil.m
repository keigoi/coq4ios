//
//  CQUtil.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQUtil.h"
#include <sys/param.h>
#include <libgen.h>

@implementation CQUtil

+(NSString*)dirnameOf:(NSString*)path
{
    char tmp[MAXPATHLEN];
    strcpy(tmp, [path UTF8String]);
    return [NSString stringWithUTF8String:dirname(tmp)];
}

+(NSString*)basenameOf:(NSString*)path
{
    char tmp[MAXPATHLEN];
    strcpy(tmp, [path UTF8String]);
    return [NSString stringWithUTF8String:basename(tmp)];
}


+(NSString*)fullPathOf:(NSString*)path
{
    if([path isAbsolutePath])
        return path;
    
    return [[NSBundle mainBundle] pathForResource:[self basenameOf:path] ofType:nil inDirectory:[self dirnameOf:path]];
}

@end
