//
//  CQVernacDocument.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/16/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQVernacDocument.h"

@implementation CQVernacDocument
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
    if ([contents length] > 0) {
        self.codeText = [[NSString alloc] initWithData:(NSData *)contents encoding:NSUTF8StringEncoding];
    } else {
        self.codeText = @"";
    }
    // TODO notify content update using delegate
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    if (!self.codeText) {
        self.codeText = @"";
    }
    NSData *docData = [self.codeText dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    return docData;
}

+ (BOOL) isValidModuleId:(NSString *)modid
{
    const NSRange NOT_FOUND = {NSNotFound, 0};
    NSRange range = [modid rangeOfString:@"^[A-Za-z_][A-Za-z0-9_]*$" options:NSRegularExpressionSearch];
    return !(range.length == NOT_FOUND.length && range.location == NOT_FOUND.location);
}
@end
