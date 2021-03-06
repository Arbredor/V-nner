//
//  WVFriendsListViewController.m
//  Vänner
//
//  Created by Jon on 4/23/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import "WVGlobalDefinitions.h"
#import "WVFriendsListViewController.h"
#import "WVViewController.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "WVAppDelegate.h"
#import "WVUtilityFunctions.h"
#import "WVFacebookDataManager.h"
#import "WVAlertsManager.h"
#import "WVFacebookFriend.h"

@interface WVFriendsListViewController ()

@end

@implementation WVFriendsListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Reset the version label - addresses enhancement issue #2
    [self.versionLabel setText:[WVUtilityFunctions getVersionLabel]];
    
    // these are now set in IB
    //    [self.tableView setDataSource:self];
    //    [self.tableView setDelegate:self];
    
    // Register reusable cells for main table view
    // -- no longer required with IB prototypes handled automatically
    //    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:WVTableViewCellIdentifier];
    
    // Register reusable cells for search bar's table view (required)
    UITableView *sctv = [self.searchCtl searchResultsTableView];
    if(sctv != nil) {
        // Prototypes changed with fix for issue #5
        //        [sctv registerClass:[UITableViewCell class] forCellReuseIdentifier:WVTableViewCellIdentifier];
        for(NSInteger i = 0; i < WVNumberCellPrototypes; i++) {
            [sctv registerClass:[UITableViewCell class] forCellReuseIdentifier:[self tableViewCellIdentifierForRow:i]];
        }
        sctv.allowsSelection = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self initOnViewAppearance];
}

// Refresh manager references and ask the Facebook data manager to clear its data structures
// and start the Graph API request chain.
- (void)initOnViewAppearance {
    // Refresh references to the Facebook data and alert managers
    WVAppDelegate *appDelegate = (WVAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate != nil) {  // none of these should ever be nil - checked first in app delegate
        self.fbDataMgr = [appDelegate fbDataMgr];
        self.alertsMgr = [appDelegate alertsMgr];
        appDelegate.lastPresentedVC = self;
    } else {                  // just in case, but it would be a very strange exception
        self.fbDataMgr = nil;
        self.alertsMgr = nil;
    }
    
    // Request friends data and add to table view
    //    [self.fbDataMgr initiateGraphAPIRequest:nil :self];
    //
    // Part of the app spec was to refresh all friends data on reactivating the app.
    // The retryAll function also starts the Graph API request chain.
    [self retryAll];
}

// Ask the Facebook data manager to clear its data structures and start the Graph API
// request chain.
- (void)retryAll {
    [self.fbDataMgr retryAll:self];
}


// Forward the search bar event to the Facebook data manager.
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    return [self.fbDataMgr searchBarTextChanged:searchText];
}


// Ask the view which requested a friend's image to reload the row data if the row index is visible.
// Assumes the row index still has the same friend in it.  The WVFacebookDataManager will force
// a UITableView reload if the rows have changed.
- (void)pictureCachedForRow:(UITableView *)view :(NSInteger)row {
    if(view == nil) {
        return;  // Very unlikely.  We have two UITableViews; without a ref, we don't know which one to update.
    }
    NSArray *visibleIndexPaths = [view indexPathsForVisibleRows];
    if(visibleIndexPaths != nil) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        if([visibleIndexPaths containsObject:indexPath]) {
            [view reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


// Forward the data source request to the Facebook data manager
// and return the appropriate number of rows in either the main
// or the search UITableView.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fbDataMgr numberOfDataRows:(tableView != self.tableView)];
}



// Added more cell prototypes in IB to increase the reusable table view cell queue.
// Now, we need to choose the cell ID, preferably row % (number of cell IDs) for even distribution.
// -- This addresses a possible race condition (issue #5) with AFNetworking's UIImageView asynchronous
//    image loading, where a quickly scrolled cell could show the wrong image until the next forced
//    update of the row's display data.
- (NSString *)tableViewCellIdentifierForRow:(NSInteger)row {
    return [NSString stringWithFormat:@"%@%li", WVTableViewCellIdentifier, row % WVNumberCellPrototypes];
}

// NOTE that the AFNetworking UIImageView extension caches the requests and the resulting images.
// Once they're loaded, the API doesn't re-request the images unless the cache has flushed them for
// memory management reasons.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *tableCell = [tableView dequeueReusableCellWithIdentifier:[self tableViewCellIdentifierForRow:indexPath.row]
                                                                 forIndexPath:indexPath];
    WVFacebookFriend *fbfriend = [self.fbDataMgr copyOfFriendAtRow:(tableView != self.tableView)
                                                                  :indexPath.row];
    BOOL fillCell = (fbfriend != nil);
    if(fillCell) {
        if(tableCell.imageView != nil) {
            [tableCell.imageView setImage:[fbfriend picture:self :tableView :indexPath.row]];
            [tableCell.imageView setNeedsLayout];
        }
        [tableCell.textLabel setText:[fbfriend name]];
    }
    return tableCell;
}


// Remove all the app's Facebook cookies.  Use to ensure the app
// will request a full log in after a log out request.
- (void)removeFacebookCookies {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *ourCookies = cookieStorage.cookies;
    NSUInteger cookieCount = [ourCookies count];
    for(NSUInteger i = 0; i < cookieCount; i++) {
        NSHTTPCookie *thisCookie = ourCookies[i];
        NSString *cookieDomain = thisCookie.domain;
        if([WVUtilityFunctions stringHasSubstring:[cookieDomain lowercaseString]
                                                 :[WVconst_cookieDomainFacebook lowercaseString]]) {
            [cookieStorage deleteCookie:thisCookie];
        }
    }
    
    // Make sure the cookie changes are actually synchronized.
    // Otherwise, they may return when restarting the app.
    //
    // If synchronize function says it didn't update anything, remove all user defaults
    // for the app by brute force so they don't come back.  (It's a bit drastic but
    //  this app is not saving anything else.)
    if(![[NSUserDefaults standardUserDefaults] synchronize]) {
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    }
}

#pragma mark - Navigation

// Update resuming flag to indicate whether or not to delete Facebook cookies.
// Perform segue to the log in view controller.
- (void)manuallyPerformSegueToLogin:(BOOL)resuming {
    self.resumingNotRelogging = resuming;
    [self performSegueWithIdentifier:segueToLogin sender:self];
}

// Perform segue to the log in view controller, optionally deleting Facebook cookies
// to force a full log in flow.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    // The Facebook reauth request assumes the user is the same.
    // Remove our app's Facebook cookies to force a full log in, possibly with a new user.
    if(!self.resumingNotRelogging) {
        [self removeFacebookCookies];
    } else {
        self.resumingNotRelogging = NO;
    }
}


@end
