//
//  CQDetailViewController.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/10/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQDetailViewController.h"
#import "CQWrapper.h"
#import "CQUtil.h"

@interface EvalUndo : NSObject
@property(assign, nonatomic) NSRange range;
+ (EvalUndo*)range:(NSRange)range;
@end
@implementation EvalUndo
+ (EvalUndo*)range:(NSRange)range;
{
    EvalUndo* me = [[EvalUndo alloc] init];
    me.range = range;
    return me;
}
@end

@interface CQDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSMutableArray* evalUndoStack;
- (void)configureView;
@end

@implementation CQDetailViewController

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

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        [CQWrapper reset];
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
    }
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showInfo:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Detail", @"Detail");
        self.evalUndoStack = [NSMutableArray array];
    }
    return self;
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

-(IBAction) onEval:(id)sender
{
    UIButton* button = sender;
    [button setEnabled:NO];
    [CQWrapper enqueueCallback:^{
        NSRange lastRange = {.location=0, .length=0};
        lastRange = self.evalUndoStack.count>0 ? ((EvalUndo*)self.evalUndoStack.lastObject).range : lastRange;
        int lastpos = lastRange.location + lastRange.length;
        
        NSString* unevaluated = [self.console.text substringFromIndex:lastpos];
        
        NSRange range = [CQWrapper nextPhraseRange:unevaluated];
        NSString* phrase = [unevaluated substringWithRange:range];
        [CQWrapper eval:phrase callback:^(BOOL success, NSString* result){
            [CQUtil showDialogWithMessage:result error:nil];
            if(success) {
                NSRange newRange = {.location=range.location+lastpos, .length=range.length};
                [self.evalUndoStack addObject:[EvalUndo range:newRange]];
            } else {
            }
            [button setEnabled:YES];
        }];
    }];    
}

-(IBAction) onUndo:(id)sender
{
}

-(IBAction) onReset:(id)sender
{
}

#pragma mark Console editing

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    
}


@end
