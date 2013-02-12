//
//  CQMasterViewController.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/10/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQMasterViewController.h"
#import "CQDetailViewController.h"
#import "CQUtil.h"

@interface CQMasterViewController ()
@property(strong,nonatomic) NSArray* files;
@end

@implementation CQMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Master", @"Master");
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        self.files = [NSArray array];
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

const NSRange NOT_FOUND = {NSNotFound, 0};
static BOOL isValidModId(NSString* name) {
    NSRange range = [name rangeOfString:@"^[A-Za-z_][A-Za-z0-9_]*$" options:NSRegularExpressionSearch];
    return !(range.length == NOT_FOUND.length && range.location == NOT_FOUND.location);
}

- (void)insertNewObject:(id)sender
{
    CQMasterViewController* wself = self;
    NSString * newName = [NSString stringWithFormat:@"NewTheory%d", (self.files.count+1)];
    
    [CQUtil showDialogWithMessage:@"Input new Vernac module name:"
                textboxWithString:newName
                         callback:^(NSString* name) {
                             if(!name) return;
                             if(!isValidModId(name)) {
                                 [CQUtil showDialogWithMessage:@"Invalid module identifier" error:nil];
                                 return;
                             }
                             NSString* path = [[[CQUtil docDir] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"v"];
                             NSFileManager* fm = [NSFileManager defaultManager];
                             BOOL result = [fm createFileAtPath:path contents:[NSData data] attributes:nil];
                             if(!result) {
                                 [CQUtil showDialogWithMessage:@"Cannot create module." error:nil];
                                 return;                                 
                             }
                             [wself refresh];
                         }];
    
}

- (void) refresh
{
    self.files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[CQUtil docDir] error:nil];
    [self.tableView reloadData];
    [self.tableView flashScrollIndicators];
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

    cell.textLabel.text = self.files[indexPath.row];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString * path = [[CQUtil docDir] stringByAppendingPathComponent:self.files[indexPath.row]];
        NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        if(nil==error) {
            [self refresh];
        } else {
            [CQUtil showDialogWithMessage:@"Can't delete that file" error:error];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // self.detailViewController.detailItem = something;
}

@end
