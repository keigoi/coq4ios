//
//  CQFlipsideViewController.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/3/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CQFlipsideViewController;

@protocol CQFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(CQFlipsideViewController *)controller;
@end

@interface CQFlipsideViewController : UIViewController

@property (weak, nonatomic) id <CQFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
