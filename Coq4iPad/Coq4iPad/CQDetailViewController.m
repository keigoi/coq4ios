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
#import "LZMAExtractor.h"

#import <CoreText/CoreText.h>

/** backstack element */
@interface BackInfo : NSObject
// status string
@property(strong,nonatomic) NSString* status;
// range of the added line(s) in console
@property(assign, nonatomic) NSRange range;
+ (BackInfo*)range:(NSRange)range status:(NSString*)status;
@end

@implementation BackInfo
+ (BackInfo*)range:(NSRange)range status:(NSString*)status
{
    BackInfo* me = [[BackInfo alloc] init];
    me.range = range;
    me.status = status;
    return me;
}
@end

@interface CQDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSMutableArray* backStack;
- (void)configureView;
@end

@implementation CQDetailViewController

// cursor position of the end of the last line accepted by Coq
-(int) lastPos
{
    NSRange lastRange = {.location=0, .length=0};
    lastRange = self.backStack.count>0 ? ((BackInfo*)self.backStack.lastObject).range : lastRange;
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
        
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

#pragma mark - initialization

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
    }
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showInfo:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)startCoqAt:(NSString*)coqroot
{
    [CQWrapper setDelegate:self];
    self.status.text = @"Initializing..";
    [CQWrapper startRuntime];
    [CQWrapper startCoq:coqroot callback:^(BOOL result){
        if(!result) {
            self.status.text = @"Error";
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.console.coloringFun = ^(NSMutableAttributedString* str){
        [self coloringOf:str];
    };
    
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    NSString* coqroot = [[CQUtil cacheDir] stringByAppendingPathComponent:@"coq-8.4pl1"];
    NSString* testvo = [coqroot stringByAppendingString:@"/theories/Arith/Arith.vo"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:testvo]) {
        
        self.status.text = @"Extracting the Coq standard library...\n";
        
        [CQWrapper runInQueue:^{
            
            [LZMAExtractor extract7zArchive:[CQUtil fullPathOf:@"coq-8.4pl1-standard-libs-for-coq4ios.7z"] dirName:coqroot preserveDir:TRUE];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.status.text = [self.status.text stringByAppendingString:@"Done.\n"];
                [self startCoqAt:coqroot];
            });
        }];
    } else {
        [self startCoqAt:coqroot];
    }
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
        self.backStack = [NSMutableArray array];
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

#pragma mark button event handlers

-(IBAction) onEval:(id)sender
{
    [CQWrapper runInQueue:^{
        int lastpos = [self lastPos];
        
        NSString* unevaluated = [self.console.text substringFromIndex:lastpos];
        
        NSRange range = [CQWrapper nextPhraseRange:unevaluated];
        if(-1==range.location) {
            self.status.text = [self.status.text stringByAppendingString:@"Syntax error.\n"];
            return;
        }
        NSString* phrase = [unevaluated substringWithRange:range];
        [CQWrapper eval:phrase callback:^(BOOL success, NSString* result){
            if(success) {
                self.status.text = [result stringByAppendingFormat:@"\n"];
                // add back stack
                NSRange newRange = {.location=range.location+lastpos, .length=range.length};
                [self.backStack addObject:[BackInfo range:newRange status:result]];
                // insert newline if we are in bottom
                if(self.lastPos==self.console.text.length) {
                    self.console.text = [self.console.text stringByAppendingString:@"\n"];
                }
                [self.console setNeedsDisplay];
            } else {
                self.status.text =
                    [self.status.text stringByAppendingString:
                        [result stringByAppendingFormat:@"\n"]];
            }
        }];
    }];    
}

-(IBAction) onBack:(id)sender
{
    if(self.backStack.count>0) {
        [self.backStack removeLastObject];
        [CQWrapper rewind:^(int extra) {
            NSRange range = {.location=self.backStack.count-extra, .length=extra};
            if(range.length>0) {
                [self.backStack removeObjectsInRange:range];
            }
            self.status.text = self.backStack.count>0 ? ((BackInfo*)self.backStack.lastObject).status : @"BackStack is empty.";
            [self.console setNeedsDisplay];
        }];
    }
}

-(IBAction) onReset:(id)sender
{
    [CQWrapper resetInitial:^{
        [self.backStack removeAllObjects];
        self.status.text = @"";
        [self.console setNeedsDisplay];
    }];
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
    [original addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)[UIColor blueColor].CGColor range:coloringRange];
}

#pragma mark Coq wrapper delegate

- (void) enterBusy
{
    self.busyOverlay.hidden = NO;
    self.backButton.enabled = NO;
    self.evalButton.enabled = NO;
}

- (void) exitBusy
{
    self.busyOverlay.hidden = YES;
    self.backButton.enabled = YES;
    self.evalButton.enabled = YES;
}

@end
