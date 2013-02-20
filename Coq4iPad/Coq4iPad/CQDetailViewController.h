//
//  CQDetailViewController.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/10/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CQFlipsideViewController.h"
#import "CQWrapper.h"

@class CQVernacDocument;
@class CQColoredTextView;

@interface CQDetailViewController
    : UIViewController <
        UISplitViewControllerDelegate,
        CQFlipsideViewControllerDelegate,
        UITextViewDelegate,
        CQWrapperDelegate
        >

@property (strong, nonatomic) CQVernacDocument* document;

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@property (weak, nonatomic) IBOutlet UIView* busyOverlay;
@property (weak, nonatomic) IBOutlet UIButton* evalButton;
@property (weak, nonatomic) IBOutlet UIButton* backButton;
@property (weak, nonatomic) IBOutlet UITextView* status;
@property (weak, nonatomic) IBOutlet CQColoredTextView* console;

// input accessory view components
@property (weak, nonatomic) IBOutlet UIView* inputAccessoryView;
-(IBAction) onInputAccTouched:(id)sender;


-(IBAction) onEval:(id)sender;
-(IBAction) onBack:(id)sender;
-(IBAction) onReset:(id)sender;
@end
