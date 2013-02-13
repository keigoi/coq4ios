//
//  CQDetailViewController.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/10/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CQFlipsideViewController.h"

@interface CQDetailViewController : UIViewController <UISplitViewControllerDelegate, CQFlipsideViewControllerDelegate, UITextViewDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@property (weak, nonatomic) IBOutlet UITextView* console;
@property (weak, nonatomic) IBOutlet UIProgressView* progress;

-(IBAction) onEval:(id)sender;
-(IBAction) onUndo:(id)sender;
-(IBAction) onReset:(id)sender;
@end
