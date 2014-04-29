//
//  WVAppDelegate.h
//  Vänner
//
//  Created by Jon on 4/19/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WVFacebookDataManager;
@class WVAlertsManager;

@interface WVAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) BOOL resuming;

@property (strong, nonatomic) WVFacebookDataManager *fbDataMgr;
@property (strong, nonatomic) WVAlertsManager       *alertsMgr;
@property (strong, nonatomic) UIViewController      *lastPresentedVC;

/* 
 application:didFinishLaunchingWithOptions: overridden to do the following:
 (1) Set up the light style status bar and show it
     (NIB seems to be ignored)
 (2) Ask the AFNetworkReachabilityManager to start monitoring network availability
 (3) Initialize all the instance references
 Returns:  Always returns YES.
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

/*
 Initializes instance references to nil, sets "resuming" to NO,
 then creates a new WVAlertsManager and a new WVFacebookDataManager.
 Do not call this function outside launch initialization.
 */
- (void)initInstanceRefs;

/* 
 Creates a new WVFacebookDataManager if one does not already exist,
 and stores the reference in a property.  On error, creates an alert
 that will call the function again on dismissal.
 */
- (void)createFacebookDataManager;

/* 
 Creates a new WVAlertsManager if one does not already exist,
 and stores the reference in a property.  On error, creates an alert.
 With no alert manager in place, the app delegate will call this
 function again when the error alert is dismissed.
 */
- (void)createAlertsManager;


/* 
 Handles the dismissal of an alert window for the failure to
 create a WVAlertsManager.  Generates another alert if creation
 fails again.
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

/* 
 Logs the details for all currently stored cookies for the app.
 NOTE:  Use ONLY for temporary debug when trying to check cookie
        removal.  Cookie data may be sensitive.
 */
- (void)debugLogCookies;


/* 
 applicationWillResignActive: has been overridden to do the following:
 (1) Set "resuming" property to YES, so app will recognize on the
 next "applicationDidBecomeActive:" call that it is not being
 called on initial launch.
 */
- (void)applicationWillResignActive:(UIApplication *)application;


/* 
 applicationDidBecomeActive: has been overridden to do the following:
 (1) If resuming from a suspended state, check if last visible
     UIViewController is the WVFriendsListViewController.
     If it is, segue to the initial log in controller to refresh tokens
     (or log in again if necessary).
 NOTE:  We could alternatively skip the segue and just reload everything,
        dealing with any token errors as they arise.  It just isn't as
        obvious that the app is reloading fresh data when using that method.
 */
- (void)applicationDidBecomeActive:(UIApplication *)application;


/*
 applicationWillTerminate: has been overridden to do the following:
 (1) Ensure that the app's user defaults (including cookies) have been updated.
 */
- (void)applicationWillTerminate:(UIApplication *)application;


@end


