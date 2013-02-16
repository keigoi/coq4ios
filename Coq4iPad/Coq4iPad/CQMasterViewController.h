//
//  CQMasterViewController.h
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/10/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CQDetailViewController;

@interface CQMasterViewController : UITableViewController

@property (strong, nonatomic) CQDetailViewController *detailViewController;
@end
