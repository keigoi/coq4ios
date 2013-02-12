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
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) CQDetailViewController *detailVC;
@end

@implementation CQAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


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
    masterViewController.managedObjectContext = self.managedObjectContext;
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
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Coq4iPad" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Coq4iPad.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
