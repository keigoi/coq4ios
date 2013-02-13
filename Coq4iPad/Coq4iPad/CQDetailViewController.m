//
//  CQDetailViewController.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/10/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQDetailViewController.h"
#import "CQColoredTextView.h"
#import "CQWrapper.h"
#import "CQUtil.h"

#import <CoreText/CoreText.h>

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

-(int) lastPos
{
    NSRange lastRange = {.location=0, .length=0};
    lastRange = self.evalUndoStack.count>0 ? ((EvalUndo*)self.evalUndoStack.lastObject).range : lastRange;
    return lastRange.location + lastRange.length;
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
    self.console.coloringFun = ^(NSMutableAttributedString* str){
        [self coloringOf:str];
    };
    
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
        int lastpos = [self lastPos];
        
        NSString* unevaluated = [self.console.text substringFromIndex:lastpos];
        
        NSRange range = [CQWrapper nextPhraseRange:unevaluated];
        if(-1==range.location) {
            [button setEnabled:YES];
            return;
        }
        NSString* phrase = [unevaluated substringWithRange:range];
        [CQWrapper eval:phrase callback:^(BOOL success, NSString* result){
            [CQUtil showDialogWithMessage:result error:nil];
            if(success) {
                NSRange newRange = {.location=range.location+lastpos, .length=range.length};
                [self.evalUndoStack addObject:[EvalUndo range:newRange]];
                [self.console setNeedsDisplay];
            } else {
            }
            [button setEnabled:YES];
        }];
    }];    
}

-(IBAction) onUndo:(id)sender
{
    if(self.evalUndoStack.count>0) {
        [self.evalUndoStack removeLastObject];
        [self.console setNeedsDisplay];
    }
}

-(IBAction) onReset:(id)sender
{
}

#pragma mark Console editing
- (void)textViewDidChange:(UITextView *)textView {
    [textView setNeedsDisplay];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[scrollView setNeedsDisplay];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(range.location < self.lastPos) return NO;
    
    //Only update the text if the text changed
	NSString* newText = [text stringByReplacingOccurrencesOfString:@"\t" withString:@"    "];
	if(![newText isEqualToString:text]) {
		textView.text = [textView.text stringByReplacingCharactersInRange:range withString:newText];
		return NO;
	}
	return YES;
}


- (void) coloringOf:(NSMutableAttributedString*)original
{
    NSRange coloringRange = {.location=0, .length=MIN([self lastPos], original.length)};
    [original addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)[UIColor redColor].CGColor range:coloringRange];
}

@end
