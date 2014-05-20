//
//  WVFriendsListViewController.h
//  Vänner
//
//  Created by Jon on 4/23/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WVAlertsManager;
@class WVFacebookDataManager;

@interface WVFriendsListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate> {
    
}


// Keep weak references to the IBOutlet objects
@property (weak, nonatomic) IBOutlet UISearchBar        *searchBar;
@property (weak, nonatomic) IBOutlet UISearchDisplayController *searchCtl;
@property (weak, nonatomic) IBOutlet UITableView        *tableView;
@property (weak, nonatomic) IBOutlet UILabel            *versionLabel;

// Keep convenience references to the WVFacebookDataManager and
// WVAlertsManager maintained by the app delegate.
@property (strong, nonatomic) WVFacebookDataManager       *fbDataMgr;
@property (strong, nonatomic) WVAlertsManager             *alertsMgr;

// Keep a flag indicating if we should or should not delete
// Facebook cookies when returning to the log in view controller.
@property (nonatomic) BOOL resumingNotRelogging;

/* initWithNibName:
 Default template routine.  No custom initialization added.
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;


/* viewDidLoad does the following:
 (1) Creates the sync dispatch queue for the image loading error flag and
 clears the flag.
 (2) Registers reusable cell IDs for both UITableViews in the view.
 */
- (void)viewDidLoad;


/* didReceiveMemoryWarning
 Default template routine.  No customization added.
 */
- (void)didReceiveMemoryWarning;


/* viewDidAppear: does the following:
 After calling [super viewDidAppear:animated], calls initOnViewAppearance.
 */
- (void)viewDidAppear:(BOOL)animated;


/* initOnViewAppearance does the following:
 (1) Refreshes references to the Facebook data manager and the alerts manager.
 (2) Start the Graph API request chain by calling retryAll.
 */
- (void)initOnViewAppearance;


/* retryAll does the following:
 Calls the retryAll: function inside the Facebook data manager to clear
 all the data structures and to start the Graph API request chain.
 */
- (void)retryAll;


/* searchBar:textDidChange: does the following:
 Forwards the event to the Facebook data manager.
 */
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;


/* tableView:numberOfRowsInSection: does the following:
 Forwards the request to the Facebook data manager.
 Returns:  The appropriate number of rows in either the main UITableView
 or the search UITableView.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;


/* tableView:cellForRowAtIndexPath: does the following:
 (1) Dequeues a reusable UITableView cell with a custom ID from the NIB.
 (2) Retrieves a decoupled copy of the Facebook friend object for the ID
 corresponding to the requested row.
 (3) If the reference to the friend object is non-nil, calls
 setTableCellImageViewForFriendWithRequest: to fill the cell's
 imageView.
 (4) Fills the cell's textLabel with the friend object's name.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;


/* tableViewCellIdentifierForRow: does the following:
 (1) Returns a new NSString with the base cell prototype ID appended
 with (row % WVNumberCellPrototypes), effectively increasing
 the reusable table view cell queue and using the mod function
 to distribute cell IDs evenly.
 -- This addresses a possible race condition (issue #5) with
 AFNetworking's UIImageView asynchronous image loading, where
 a quickly scrolled cell could show the wrong image until the
 next forced update of the row's display data.
 */
- (NSString *)tableViewCellIdentifierForRow:(NSInteger)row;


/* manuallyPerformSegueToLogin: does the following:
 Updates the self.resumingNotRelogging flag and requests a segue
 to the log in view controller.
 */
- (void)manuallyPerformSegueToLogin:(BOOL)resuming;


/* removeFacebookCookies does the following:
 (1) Deletes all cookies for the Facebook domain so a future segue to
 the log in view controller will force a full log in flow.
 (2) Synchronizes user defaults or forces removal of all user defaults
 information if synchronization failed.  (App doesn't save anything
 else to user defaults anyway.)
 */
- (void)removeFacebookCookies;


/* prepareForSegue: does the following:
 Checks the self.resumingNotRelogging flag to optionally delete
 all Facebook cookies before the segue to the log in view controller.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;


/* pictureCachedForRow: does the following:
 Asks the non-nil view (which probably requested the friend's image)
 to reload the associated row data if the row is visible.
 This function should be called on successful completion of a
 friend's image fetch.  It shouldn't be needed if the image was
 already cached.
 Assumes the row index still has the same friend in it.  The
 WVFacebookDataManager will force a UITableView reload if the rows
 have changed.
 */
- (void)pictureCachedForRow:(UITableView *)view :(NSInteger)row;

@end
