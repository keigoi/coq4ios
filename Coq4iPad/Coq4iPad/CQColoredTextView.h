//
//  CQColoredTextView.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/13/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CQColoringFun)(NSMutableAttributedString*);

@interface CQColoredTextView : UITextView
@property(strong,nonatomic) CQColoringFun coloringFun;
@end
