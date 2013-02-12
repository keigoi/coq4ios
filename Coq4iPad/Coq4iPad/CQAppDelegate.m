//
//  CQAppDelegate.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/3/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQAppDelegate.h"

#import "CQMasterViewController.h"
#import "CQDetailViewController.h"
#import "CQWrapper.h"
#import "CQUtil.h"

@interface CQAppDelegate ()
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) CQDetailViewController *detailVC;
@end

@implementation CQAppDelegate

- (void)prepare
{
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
                [self.detailVC.progress setProgress:(float)count/all animated:YES];
            }];
        }
        
        [CQWrapper loadInitial];
        
        for(NSString* f in rests) {
            [CQWrapper compile:f callback:^{
                count++;
                [self.detailVC.progress setProgress:(float)count/all animated:YES];
            }];
        }
    }];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    
    CQMasterViewController *masterViewController = [[CQMasterViewController alloc] initWithNibName:@"CQMasterViewController" bundle:nil];
    UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    
    CQDetailViewController *detailViewController = [[CQDetailViewController alloc] initWithNibName:@"CQDetailViewController" bundle:nil];
    UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    
    masterViewController.detailViewController = detailViewController;
    
    self.splitViewController = [[UISplitViewController alloc] init];
    self.splitViewController.delegate = detailViewController;
    self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
    
    self.detailVC = detailViewController;
    
    [self prepare];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // TODO save changes!!
}

@end
