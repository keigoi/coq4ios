//
//  CQMainViewController.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/3/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQFlipsideViewController.h"

#import <CoreData/CoreData.h>

@interface CQMainViewController : UIViewController <CQFlipsideViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@property (weak, nonatomic) IBOutlet UITextView* console;
@property (weak, nonatomic) IBOutlet UIProgressView* progress;

- (IBAction)showInfo:(id)sender;

@end
