//
//  CQDetailViewController.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/10/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQDetailViewController.h"
#import "CQVernacDocument.h"
#import "CQWrapper.h"
#import "CQUtil.h"
#import "LZMAExtractor.h"

#import <CoreText/CoreText.h>

/**
 * backstack (a.k.a "undo" stack of evaluation) element
 */
@interface BackInfo : NSObject
// status string of that time
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

#pragma mark - CQDetailViewController

@interface CQDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSMutableArray* backStack;
@end

@implementation CQDetailViewController

// cursor position of the end of the last line accepted by Coq
-(int) lastPos
{
    NSRange lastRange = {.location=0, .length=0};
    lastRange = self.backStack.count>0 ? ((BackInfo*)self.backStack.lastObject).range : lastRange;
    int pos = lastRange.location + lastRange.length;
    if(pos < self.console.text.length && 0x0A==[self.console.text characterAtIndex:pos]) {
        pos++;
    }
    return pos;
}

#pragma mark - initialization & finalization


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Empty Theory", @"Empty Theory (initial title string for editing view)");
        self.backStack = [NSMutableArray array];
    }
    return self;
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.document) {
        self.title = self.document.fileURL.lastPathComponent;
        [self setConsoleText:self.document.codeText];
    }
}

- (void)startCoqAt:(NSString*)coqroot
{
    [CQWrapper setDelegate:self];
    self.status.text = @"Initializing..";
    [CQWrapper startRuntime];
    [CQWrapper startCoq:coqroot callback:^(BOOL result){
        if(result) {
            self.status.text = [self.status.text stringByAppendingString:@"Done.\n"];
        } else {
            self.status.text = @"Error"; // FIXME more detailed diagnosis message?
        }
    }];
}

- (void)prepareCoq
{
    
    // If stdlib does not exist in cache directory, expand it from the 7z archive
    NSString* coqroot = [[CQUtil cacheDir] stringByAppendingPathComponent:@"coq-8.4pl2"];
    NSString* testvo = [coqroot stringByAppendingString:@"/theories/Arith/Arith.vo"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:testvo]) {
        
        self.status.text = @"Installing the Coq standard library...\n";
        
        [CQWrapper runInQueue:^{
            
            [LZMAExtractor extract7zArchive:[CQUtil fullPathOf:@"coq-8.4pl2-standard-libs-for-coq4ios.7z"] dirName:coqroot preserveDir:TRUE];
            
            // and start Coq
            dispatch_async(dispatch_get_main_queue(), ^{
                self.status.text = [self.status.text stringByAppendingString:@"Done.\n"];
                [self startCoqAt:coqroot];
            });
        }];
    } else {
        [self startCoqAt:coqroot];
    }
    
    [[NSBundle mainBundle] loadNibNamed:@"CQKeyboardAccessories-portlait"
                                                         owner:self
                                                       options:nil];

    self.console.inputAccessoryView = self.inputAccessoryView;
}

- (void)viewDidLoad
{
    NSLog(@"detail view: didload");
    [super viewDidLoad];
    
    // status bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showInfo:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self configureView];

    [self prepareCoq];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"DetailView: will appear");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.document closeWithCompletionHandler:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Managing the document

- (void)setDocument:(CQVernacDocument *)document
{
    if (self.document != document) {
        // close (and save) old document
        [self.document closeWithCompletionHandler:nil];
        [self.backStack removeAllObjects];
        if(CQWrapper.isReady) {
            [CQWrapper resetInitial:^{}]; // FIXME here we should clear the camlQueue instead            
        }
        
        // open new document
        NSLog(@"Opening document: %@", document.fileURL.path);
        self->_document = document;
        
        __weak CQDetailViewController* wself = self;
        [self.document openWithCompletionHandler:^(BOOL success){
            if(success) {
                [wself configureView];
            } else {
                [CQUtil showDialogWithMessage:@"Cannot open document" error:nil];
            }
        }];
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}


#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(CQVersionInfoViewController *)controller
{
    [self.flipsidePopoverController dismissPopoverAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{
    if (!self.flipsidePopoverController) {
        CQVersionInfoViewController *controller = [[CQVersionInfoViewController alloc] initWithNibName:@"CQVersionInfoViewController" bundle:nil];
        controller.delegate = self;
        
        self.flipsidePopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
    }
    if ([self.flipsidePopoverController isPopoverVisible]) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    } else {
        [self.flipsidePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}


#pragma mark Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Files", @"File list button label on Console's navibar left");
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
                    [self setConsoleText:[self.console.text stringByAppendingString:@"\n"]];
                }
            } else {
                self.status.text =
                    [self.status.text stringByAppendingString:
                        [result stringByAppendingFormat:@"\n"]];
            }
            [self refreshConsoleText];
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
            [self refreshConsoleText];
        }];
    }
}

-(IBAction) onReset:(id)sender
{
    [CQWrapper resetInitial:^{
        [self.backStack removeAllObjects];
        self.status.text = @"";
        [self refreshConsoleText];
    }];
}

#pragma mark Console editing
- (void)undoCodeText:(NSString*)codeText
{
    self.document.codeText = codeText;
    [self setConsoleText:codeText];
}


- (void)textViewDidChange:(UITextView *)textView {
    
    NSString* currentText = self.document.codeText;
    
    // update CQVernacDocument with the latest UITextView content
    self.document.codeText = textView.text;
    
    // this triggers auto-save in CQVernacDocument
    [_document.undoManager registerUndoWithTarget:self
                                         selector:@selector(undoCodeText:)
                                           object:currentText];
    
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

- (void) setConsoleText:(NSString*)original
{
    UIFont* systemFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    
    original = original ?: @"";
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithString:original];
    NSRange coloringRange = {.location=0, .length=[self lastPos]};
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:coloringRange];
    int pos = MIN([self lastPos]+1, text.length);
    NSRange noColorRange = {.location=pos, .length=text.length-pos};
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:noColorRange];
    NSRange wholeRange = {.location=0, .length=text.length};
    [text addAttribute:NSFontAttributeName value:systemFont range:wholeRange];
    
    // FIXME: tedious bookkeeping!
    NSRange selection = self.console.selectedRange;
    self.console.scrollEnabled = NO;
    self.console.attributedText = text;
    self.console.scrollEnabled = YES;
    selection.location = MIN(selection.location, original.length);
    selection.length = 0;
    self.console.selectedRange = selection;
    
    self.console.typingAttributes = @{NSFontAttributeName:systemFont, NSForegroundColorAttributeName:[UIColor blackColor]};
}

- (void) refreshConsoleText
{
    [self setConsoleText:self.console.text];
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

#pragma mark input accessory view button

- (IBAction)onInputAccTouched:(id)sender
{
    UIButton* button = sender;
    NSString* text = [button.titleLabel.text stringByAppendingString:@" "];
    [self setConsoleText:[self.console.text stringByAppendingString:text]];
    NSRange selection = {.location=self.console.text.length, .length=0};
    self.console.selectedRange = selection;
}

#pragma mark keybord show/hide event handling
- (void)keyboardWillShown:(NSNotification*)aNotification
{
    [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    [self moveTextViewForKeyboard:aNotification up:NO];
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up {
    NSDictionary* userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect newFrame = self.view.superview.bounds;
    if(up) {
        CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
        newFrame.size.height -= keyboardFrame.size.height;
    }
    self.view.frame = newFrame;
    
    [UIView commitAnimations];
}

@end
