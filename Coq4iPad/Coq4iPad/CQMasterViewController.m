//
//  CQMasterViewController.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/10/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQMasterViewController.h"
#import "CQDetailViewController.h"
#import "CQVernacDocument.h"
#import "CQUtil.h"

@interface CQMasterViewController ()
@property(assign,nonatomic) BOOL _createFile;
@property(strong,nonatomic) NSArray* files;
@end

@implementation CQMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"File list", @"Title label for file list (master) view");
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        self.files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[CQUtil docDir] error:nil];
        self._createFile = TRUE;
    }
    return self;
}

- (NSString*)newModuleId
{
    return [NSString stringWithFormat:@"NewTheory%d", (self.files.count+1)];
}

- (NSString*)currentFile
{
    return [self.detailViewController.document.fileURL lastPathComponent];
}

- (void)openDocument:(NSString*)item
{
    if([self.currentFile isEqualToString:item]) {
        // already opened
        [self dismissModalViewControllerAnimated:TRUE];
        return;
    }
    NSURL* url = [NSURL fileURLWithPath:[[CQUtil docDir] stringByAppendingPathComponent:item]];
    self.detailViewController.document = [[CQVernacDocument alloc] initWithFileURL:url];
}

- (void)openNewDocument:(NSString*)newFileName
{
    if([self.files containsObject:newFileName]) {
        NSString* msg = [NSString stringWithFormat:@"File with the same name already exists: %@", newFileName];
        [CQUtil showDialogWithMessage:msg error:nil];
        return;
    }
    
    NSURL* newUrl = [NSURL fileURLWithPath:[[CQUtil docDir] stringByAppendingPathComponent:newFileName]];
    
    CQVernacDocument* newDoc = [[CQVernacDocument alloc] initWithFileURL:newUrl];
    
    // set initial content
    newDoc.codeText = [NSString stringWithContentsOfFile:[CQUtil fullPathOf:@"InitialVernacConsoleContent.v"]
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
    
    [newDoc saveToURL:newDoc.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (success) {
            [self refresh];
            [self openDocument:newFileName];
        } else {
            NSString* msg = [NSString stringWithFormat:@"Cannot create new module: %@", newFileName];
            [CQUtil showDialogWithMessage:msg error:nil];
        }
    }];    
}

#pragma mark initialization

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // toolbar
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onInsertNewDocument:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    // open most recent document
    if(self.files.count>0) {
        [self openDocument:self.files[0]];
        
    } else if(self._createFile) { // if there's no file, create an empty one on startup

        self._createFile = FALSE;
        
        NSString* newFileName = [[self newModuleId] stringByAppendingPathExtension:@"v"];
        [self openNewDocument:newFileName];
    }
    
    [self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) refresh
{
    self.files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[CQUtil docDir] error:nil];
    [self.tableView reloadData];
    [self.tableView flashScrollIndicators];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}

#pragma mark - event handlers

- (void)onInsertNewDocument:(id)sender
{
    CQMasterViewController* wself = self;
    NSString * newName = [self newModuleId];
    
    [CQUtil showDialogWithMessage:@"Input new Vernac module name:"
                textboxWithString:newName
                         callback:^(NSString* name) {
                             if(!name) return;
                             if([CQVernacDocument isValidModuleId:name]) {
                                 NSString* newFileName = [name stringByAppendingPathExtension:@"v"];
                                 [self openNewDocument:newFileName];
                                 [wself refresh];
                             } else {
                                 [CQUtil showDialogWithMessage:@"Invalid module identifier" error:nil];
                                 return;
                             }
                         }];
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.files.count; /* num of files */
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    NSString* filename = self.files[indexPath.row];
    cell.textLabel.text = filename;
    cell.textLabel.textColor = [filename isEqualToString:self.currentFile] ? [UIColor blueColor] : [UIColor blackColor];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ![self.currentFile isEqualToString:self.files[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString * path = [[CQUtil docDir] stringByAppendingPathComponent:self.files[indexPath.row]];
        NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if(nil==error) {
            [self refresh];
        } else {
            [CQUtil showDialogWithMessage:@"Can't delete that file" error:error];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self openDocument:self.files[indexPath.row]];
    [self.tableView reloadData];
}

@end
