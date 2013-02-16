//
//  CQVernacDocument.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/16/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CQVernacDocument : UIDocument
@property(strong,nonatomic) NSString* codeText;

+(BOOL)isValidModuleId:(NSString*)modid;
@end
