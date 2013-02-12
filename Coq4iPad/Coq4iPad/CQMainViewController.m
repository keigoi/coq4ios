//
//  CQMainViewController.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/3/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQMainViewController.h"

#import "CQWrapper.h"
#import "CQUtil.h"

@interface CQMainViewController ()

@end

@implementation CQMainViewController

#pragma mark ViewController callbacks

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString* cacheDir = [CQUtil cacheDir];
    NSString* target = [cacheDir stringByAppendingString:@"/coq-8.4pl1"];
    NSError* error;
    [[NSFileManager defaultManager] removeItemAtPath:target error:&error];
    if(error) {
        NSLog(@"%@", [error localizedDescription]);
        error = nil;
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:TRUE attributes:nil error:&error];
    if(error) {
        NSLog(@"%@", [error localizedDescription]);
        error = nil;
    }
    [[NSFileManager defaultManager] copyItemAtPath:[CQUtil fullPathOf:@"coq-8.4pl1"]
                                            toPath:target
                                             error:&error];
    if(error) {
        NSLog(@"%@", [error localizedDescription]);
        error = nil;
    }
    
    [CQWrapper startRuntime];
    [CQWrapper startCoq:target callback:^{
        NSArray* inits = [CQWrapper initTheories];
        NSArray* rests = [CQWrapper restTheories];
        
        __block int count = 0;
        int all = inits.count + rests.count;
        
        for(NSString* f in inits) {
            [CQWrapper compile:f callback:^{
                count++;
                [self.progress setProgress:(float)count/all animated:YES];
            }];
        }
        
        [CQWrapper loadInitial];
        
        for(NSString* f in rests) {
            [CQWrapper compile:f callback:^{
                count++;
                [self.progress setProgress:(float)count/all animated:YES];
            }];
        }
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(CQFlipsideViewController *)controller
{
    [self.flipsidePopoverController dismissPopoverAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{
    if (!self.flipsidePopoverController) {
        CQFlipsideViewController *controller = [[CQFlipsideViewController alloc] initWithNibName:@"CQFlipsideViewController" bundle:nil];
        controller.delegate = self;
        
        self.flipsidePopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
    }
    if ([self.flipsidePopoverController isPopoverVisible]) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    } else {
        [self.flipsidePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

@end
