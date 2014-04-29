//
//  WVAppDelegate.m
//  Vänner
//
//  Created by Jon on 4/19/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import "WVGlobalDefinitions.h"
#import "WVAppDelegate.h"
#import "WVFacebookDataManager.h"
#import "WVAlertsManager.h"
#import "AFNetworking.h"
#import "WVFriendsListViewController.h"

@implementation WVAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Ensure status bar uses the light style and make it appear.
    // NIB settings seem to be ignored, so it's easy enough to do it manually.
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    [application setStatusBarHidden:NO withAnimation:YES];
    
    // Start monitoring network accessibility and set up properties.
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [self initInstanceRefs];

    return YES;
}

// Initialize all relevant properties, create the WVAlertsManager
// for handling alert dialogs, and create the WVFacebookManager
// for fetching and storing Facebook friend data.
- (void)initInstanceRefs {
    _alertsMgr = nil;
    _fbDataMgr = nil;
    _resuming = NO;
    _lastPresentedVC = nil;
    
    [self createAlertsManager];
    [self createFacebookDataManager];
}

// Create a new WVFacebookDataManager or alert on error.
// Alert window will call this function again on dismissal.
- (void)createFacebookDataManager {
    if(_fbDataMgr == nil) {
        _fbDataMgr = [[WVFacebookDataManager alloc] init];
        // If we didn't get one for whatever reason, throw an alert if possible and exit
        if(_fbDataMgr == nil) {
            // If we are this far already, the alerts manager should be non-nil.
            [self.alertsMgr genericAlert:@"Error" :@"Could not create a manager object for the Facebook data.  If this message appears multiple times, please restart the app."
                                        :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                            [self createFacebookDataManager];
                                        }];
        }
    }
}

// Failure to allocate an alerts manager will trigger this path
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self createAlertsManager];
}
    
// Create a new WVAlertsManager or alert on error.
// With no alert manager in place, when the UIAlertView is dismissed, this object's
// UIAlertView delegate function will call this function again.
- (void)createAlertsManager {
    if(_alertsMgr == nil) {
        _alertsMgr = [[WVAlertsManager alloc] init];
        if(_alertsMgr == nil) {
            UIAlertView *bareAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Could not create an alerts manager object for the app.  If this message appears multiple times, please kill and restart the app."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [bareAlert show];
        }
    }
}

// Logs the details for all currently stored cookies.
// NOTE - Use ONLY for temporary debug when trying to check cookie removal.
- (void)debugLogCookies {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *ourCookies = cookieStorage.cookies;
    NSUInteger cookieCount = [ourCookies count];
    for(NSUInteger i = 0; i < cookieCount; i++) {
        NSHTTPCookie *thisCookie = ourCookies[i];
        NSLog(@"Cookie %lu is %@", (unsigned long)i, thisCookie);
    }
}

// Set "resuming" flag when going inactive so the app knows
// when it returns that it is not the initial launch.
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    _resuming = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if(_resuming) {
        if([_lastPresentedVC isMemberOfClass:[WVFriendsListViewController class]]) {
            // If we want to get new tokens every time, just segue to the login screen, with this:
            [(WVFriendsListViewController *)_lastPresentedVC manuallyPerformSegueToLogin:YES];

            // -- We can do the following instead of going back through the login screen,
            //    although it isn't as obvious that we've reloaded the data (as requested
            //    for the exercise).

            // ONLY for testing error handling with a rejected auth_token
            //            self.fbDataMgr.authToken = @"badtoken";
            
            // Reload friends data; complain if Facebook has an issue (like token expiration).
            // [(WVFriendsListViewController *)_lastPresentedVC initOnViewAppearance];
        }
    }
}

// Ensure that the app's user defaults (including cookies) have been updated.
- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/* Unused template functions
 
 - (void)applicationDidEnterBackground:(UIApplication *)application
 {
 // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
 // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
 }
 
 - (void)applicationWillEnterForeground:(UIApplication *)application
 {
 // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
 }
 
*/

@end
