//
//  WVFacebookDataManager.h
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WVAlertsManager;
@class WVFriendsListViewController;
@class WVFacebookFriend;

@interface WVFacebookDataManager : NSObject

// Auth token provided by the log in process
@property (strong, nonatomic) NSString *authToken;

// A reference to the alerts manager for creating error alerts
@property (strong, nonatomic) WVAlertsManager *alertsMgr;

// Sorted list of Facebook friend IDs (sorted alphabetically by name)
@property (strong, nonatomic) NSArray *dataSourceIDs;
// Filtered list of indices into the dataSourceIDs array
@property (strong, nonatomic) NSArray *filteredDataSourceIndices;

// Dispatch group and queue for protecting access to the friend data
@property (strong, nonatomic) dispatch_group_t dataAccessQueueGroup;
@property (strong, nonatomic) dispatch_queue_t dataAccessQueue;

// Primary friend data lookup dictionary
// id -> WVFacebookFriend object with the data for the id
@property (strong, nonatomic) NSMutableDictionary *friendDataDict;
// Indicates if friend data has changed since last table update
@property (nonatomic) BOOL dataUpdatedSincePull;

// Lookup dictionary for already calculated searches of friend names
// filter string -> array of filtered indices into the dataSourceIDs array
@property (strong, nonatomic) NSMutableDictionary *nameSearches;
// Indicates if friend data has changed; checked on a search event
@property (nonatomic) BOOL searchesAreInvalid;

/*
 init does the following:
 (1) Grabs a reference to the alerts manager for creating error alerts
 (2) Creates a sync dispatch group and queue to protect the Facebook friend data
 (3) Calls initStructures to init all other relevant properties
 Returns:  id of the object on success; nil on failure
 */
- (id)init;


/*
 initStructures does the following:
 (1) Synchronously initializes the following properties:
  (a) friendDataDict - new with 100 friend initial capacity
  (b) dataSourceIDs - new with 100 friend initial capacity
  (c) nameSearches - new with 20 substring initial capacity
  (d) dataUpdatedSincePull and searchesAreInvalid - YES to indicate dirty data
  (e) filteredDataSourceIndices - nil (indicates no current filter)
 */
- (void)initStructures;


/*
 retryAll: does the following:
 (1) Re-initializes all structures (via initStructures)
 (2) Updates the data source lists and asks the UITableViews to reload data
     so that the re-initialization is clearly visible
 (3) Calls checkNetworkAndStartGraphChain: to restart the Graph API request chain
 */
- (void)retryAll:(WVFriendsListViewController *)friendsLVCtl;


/*
 checkNetworkAndStartGraphChain: does the following:
 (1) Checks network accessibility
 (2) Alerts for a problem or restarts the Graph API request chain
 */
- (void)checkNetworkAndStartGraphChain:(WVFriendsListViewController *)friendsLVCtl;


/*
 initiateGraphAPIRequest: does the following:
 (1) Gets a new Graph API request string based on the previous response
 (2) If no more requests, waits for all queued processing to finish,
     updates the data source and table views, and returns
 (3) For a new request, generates the AFNetworking request operation and
     requests the JSON serializer.
 (4) Sets up the success and failure blocks.
   (a) For success, attempts to fill the internal data structures from the response
   (b) For no errors in the data, updates the data source and the table views, and
       launches the next request in the Graph API chain
   (c) With errors in the data, empties the queue and updates the data source and the
       table views, but does NOT continue the Graph API chain
   (d) For failure, if it's an authentication problem, alerts the user and
       sends him back to the log in view controller; if it's another problem
       allows the user to retry or log in again.  Does NOT flush cookies here.
 (5) Launches the request operation.
 */
- (void)initiateGraphAPIRequest:(NSDictionary *)responseDict :(WVFriendsListViewController *)friendsListVC;


/* generateGraphAPIRequestStringFromLastResponse:
 Returns:  Initial Graph API request string if incoming dictionary is nil,
           or returns a URL string from nextPagingURLFromResponseDict:
 */
- (NSString *)generateGraphAPIRequestStringFromLastResponse:(NSDictionary *)responseDict;


/* fillDictsFromResponseDict: does the following:
 (1) Checks for and alerts the user about any data error in the response dict
 (2) On no error with the Graph API data, get the friend data from the response
     and call createFriendsFromFBFriendDataDictList: to create friend objects
     and to update the internal data structures
 (3) On any missing data, alert the user and ask him to accept the missing
     data or to retry the request
 Returns:  YES if friend objects have been created and added to the internal
           structures; NO if errors skipped friend object creation.
 */
- (BOOL)fillDictsFromResponseDict:(NSDictionary *)responseDict :(WVFriendsListViewController *)friendsListVC;


/* createFriendsFromFBFriendDataDictList: does the following:
 (1) Pulls the Facebook ID and friend name from the friend data dictionary
 (2) Looks for the picture data dictionary and pulls the picture URL
 (3) Tracks missing info; substitutes empty string for missing picture URL
 (4) Synchronously updates self.friendDataDict with a new WVFacebookFriend
     object with the ID, name, and picture URL string.
     Sets self.dataUpdateSincePull to indicate that tables should be updated
     and future searches will be invalid.
 Returns:  YES if no errors occurred; otherwise, NO.
 */
- (BOOL)createFriendsFromFBFriendDataDictList:(NSArray *)friendDictList;


/* nextPagingURLFromResponseDict:
 Returns:  The paging string for the next step in the Graph API chain
           if the response dict is non-nil, has a paging dict, and
           the paging dict has a value for the "next" key; otherwise, nil.
 */
- (NSString *)nextPagingURLFromResponseDict:(NSDictionary *)responseDict;


/* handleFacebookGraphErrorResponse: does the following:
 (1) Checks if the valid Graph API response indicates an error
 (2) If it does, and the error is an authentication exception,
     alerts the user and allows him to retry or to log in again.
 (3) On any other problem, alerts the user to the problem and
     allows him to retry the Graph API request chain.
 Returns:  YES if it caught and alerted an error, NO otherwise.
 */
- (BOOL)handleFacebookGraphErrorResponse:(NSDictionary *)responseDict :(WVFriendsListViewController *)friendsListVC;


/* waitForGraphRequestsAndUpdateLists: does the following:
 (1) Waits for all requests in the dispatch group to complete,
     then updates the data source and the table views.
 NOTE:  This function currently submits itself asynchronously to
        the main queue and returns immediately.
 */
- (void)waitForGraphRequestsAndUpdateLists:(WVFriendsListViewController *)friendsListVC;


/* searchBarTextChanged: does the following:
 (1) On any change to the search bar filter string, looks for a cached
     index array for the filter string.
 (2) It keeps stripping the filter string until it finds a match with a
     previous search string.
 (3) If it finds a match, and it matches the current filter string, sets
     self.filteredDataSourceIndices to the cached index array.
 (4) If it finds a match, but it doesn't match the current filter string,
     it uses the cached index array as a starting point for another search.
 (5) If it finds no match, it uses the full list of IDs as a starting point
     for another search.
 (6) Generates a new array of filtered indices, updates
     self.filteredDataSourceIndices, and caches the array for future searches.
 */
- (void)searchBarTextChanged:(NSString *)searchText;


/* filterNameArrayBySubstring: does the following:
 (1) If startingArray is not nil, uses it to get the already filtered IDs
     from the full array of IDs.  For each ID, it looks up the friend object,
     retrieves the name, and looks for a substring match.  On success, adds
     the ID to the new list of filtered ID indices.
 (2) If startingArray is nil, uses the full ID list.  Does the same thing
     as (1) with substring matches.
 Returns:  New NSArray with a list of filtered indices into the full ID array.
 */
- (NSArray *)filterNameArrayBySubstring:(NSArray *)startingArray :(NSString *)filter;


/* updateDataSourceLists: does the following:
 (1) Synchronously updates the internal data structures if the data has
     changed since the last update.  Clears data dirty flag and sets search
     dirty flag.
 (2) Asks all table views to reload their data.
 */
- (void)updateDataSourceLists:(WVFriendsListViewController *)friendsListVC;


/* sortIDsByNames: does the following:
 NOTE:  This should always be called inside a dispatch_sync block.  Do NOT
        layer another dispatch block inside it.
 (1) Sorts IDs in an array based on the names of the WVFacebookFriend objects
     stored in self.friendDataDict
 Returns:  A new NSArray with a list of IDs sorted by name.
 */
- (NSArray *)sortIDsByNames:(NSArray *)idList;


/* numberOfDataRows:
 Returns:  Either the number of elements in the sorted dataSourceIDs array
           (all friends) or the filteredDataSourceIndices array, depending on
            (a) which UITableView requests the information, or
            (b) whether a valid search filter is active (non-nil)
 */
- (NSInteger)numberOfDataRows:(BOOL)forSearchTable;


/* copyOfFriendAtRow:
 Returns:  A decoupled copy of the WVFacebookFriend object for the appropriate
           row in the main or search table view.  Uses the same criteria
           as numberOfDataRows: to determine if it should start with the
           dataSourceIDs array or the filteredDataSourceIndices array.
 */
- (WVFacebookFriend *)copyOfFriendAtRow:(BOOL)forSearchTable :(NSInteger)row;

@end
