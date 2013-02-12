//
//  CQUtil.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQUtil.h"
#include <sys/param.h>
#include <libgen.h>

#pragma mark private class UIAlertViewWithCallback implementation

// 閉じた時にコールバックを呼んでくれる UIAlertView
@interface UIAlertViewWithCallback : UIAlertView <UIAlertViewDelegate>
-(id)initWithMessage:text callback:(void (^)(void))callback;
-(id)initWithMessage:text textboxWithString:(NSString*)text callback:(void (^)(NSString*))callback;
@end

@implementation UIAlertViewWithCallback {
    void (^_callback)(void);
    void (^_callbackWithText)(NSString*);
}

-(id) initWithMessage:message callback:(void (^)(void))callback
{
    if(self = [super initWithTitle:nil message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil]) {
        self->_callback = callback;
    }
    return self;
}

-(id)initWithMessage:message textboxWithString:(NSString*)text callback:(void (^)(NSString*))callback
{
    if(self = [super initWithTitle:nil message:message delegate:self cancelButtonTitle:@"キャンセル" otherButtonTitles:@"OK", nil]) {
        self->_callbackWithText = callback;
        self.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField* textfield = [self textFieldAtIndex:0];
        textfield.text = text;
    }
    return self;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(_callback) {
        _callback();
    } else if(_callbackWithText) {
        if(self.cancelButtonIndex==buttonIndex) {
            _callbackWithText(nil);
        } else {
            UITextField* textfield = [self textFieldAtIndex:0];
            _callbackWithText(textfield.text);
        }
    }
}

@end


#pragma mark CQUtil implementation

@implementation CQUtil

+(NSString*)dirnameOf:(NSString*)path
{
    char tmp[MAXPATHLEN];
    strcpy(tmp, [path UTF8String]);
    return [NSString stringWithUTF8String:dirname(tmp)];
}

+(NSString*)basenameOf:(NSString*)path
{
    char tmp[MAXPATHLEN];
    strcpy(tmp, [path UTF8String]);
    return [NSString stringWithUTF8String:basename(tmp)];
}


+(NSString*)fullPathOf:(NSString*)path
{
    if([path isAbsolutePath])
        return path;
    
    return [[NSBundle mainBundle] pathForResource:[self basenameOf:path] ofType:nil inDirectory:[self dirnameOf:path]];
}


+(NSString*)cacheDir
{
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSCachesDirectory
                                             inDomains:NSUserDomainMask];
    if ([possibleURLs count] < 1) {
        @throw @"no cache directory found";
    }
    
    NSURL* cachesUrl = [possibleURLs objectAtIndex:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString* dir = [[cachesUrl URLByAppendingPathComponent:appBundleID] path];
    
    return dir;
}

// Returns the URL to the application's Documents directory.
+(NSString *)docDir
{
    NSURL* docUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [docUrl path];
}

+(void)runInMainThread:(void(^)(void))callback
{
    if(!callback) return;
    if([NSThread isMainThread]) {
        callback();
    } else {
        dispatch_async(dispatch_get_main_queue(), callback);
    }
}

+(void) showDialogWithMessage:(NSString*)message error:(NSError*)error callback:(void (^)(void))callback
{
    NSString* text =
    error == nil
    ? message
    : [NSString stringWithFormat:@"%@ (%@)", message, [error localizedDescription]];
    
    [self runInMainThread:^{
        UIAlertView* view = [[UIAlertViewWithCallback alloc] initWithMessage:text callback:callback];
        [view show];
    }];
}

+(void) showDialogWithMessage:(NSString*)message error:(NSError*)error
{
    [self showDialogWithMessage:message error:error callback:nil];
}

+(void) showDialogWithMessage:(NSString*)message textboxWithString:(NSString*)text callback:(void(^)(NSString*))callback;
{
    [self runInMainThread:^{
        UIAlertView* view = [[UIAlertViewWithCallback alloc] initWithMessage:message textboxWithString:text callback:callback];
        [view show];
    }];
}

@end
