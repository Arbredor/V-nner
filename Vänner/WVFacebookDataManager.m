//
//  WVFacebookDataManager.m
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import "WVGlobalDefinitions.h"
#import "WVFacebookDataManager.h"
#import "AFNetworking.h"
#import "WVAppDelegate.h"
#import "WVUtilityFunctions.h"
#import "WVAlertsManager.h"
#import "WVFriendsListViewController.h"
#import "WVFacebookFriend.h"


// GET example for querying graph API
// https:
//  //graph.facebook.com/me/friends?fields=id,first_name,last_name,picture.width(50).height(50)

@implementation WVFacebookDataManager

// Grab reference to alerts manager, create dispatch group/queue for Facebook data,
// and return object id.
- (id)init {
    self = [super init];
    if(self != nil) {
        _alertsMgr = [(WVAppDelegate *)[[UIApplication sharedApplication] delegate] alertsMgr];
        
        _dataAccessQueue = dispatch_queue_create("com.spd.wvDataAccessQueue", NULL);
        _dataAccessQueueGroup = dispatch_group_create();
        
        [self initStructures];
    }
    return self;
}

// Safely initialize relevant Facebook friend data structures with reasonable
// starting capacities.  Indicate dirty data.
- (void)initStructures {
    dispatch_sync(_dataAccessQueue, ^() {
        _friendDataDict = [NSMutableDictionary dictionaryWithCapacity:100];
        _dataUpdatedSincePull = YES;
        _searchesAreInvalid = YES;
        _dataSourceIDs = [NSMutableArray arrayWithCapacity:100];
        _nameSearches = [NSMutableDictionary dictionaryWithCapacity:20];
        _filteredDataSourceIndices = nil;
    });
}

// Retry all data collection, using the view controller reference
// to target the table view that should reload data.
- (void)retryAll:(WVFriendsListViewController *)friendsLVCtl {
    [self initStructures];
    [self updateDataSourceLists:friendsLVCtl];  // make the refresh visible immediately
    [self checkNetworkAndStartGraphChain:friendsLVCtl];
}

// Check that the network is reachable, then start the paged Facebook
// Graph API request chain.  Error alert will call this again on dismissal.
- (void)checkNetworkAndStartGraphChain:(WVFriendsListViewController *)friendsLVCtl {
    if(![AFNetworkReachabilityManager sharedManager].reachable) {
        [self.alertsMgr genericCustomCancelAlert:@"Network error"
                                                :@"Please check your connection to WiFi or enable cellular data, then press Retry to continue."
                                                :@"Retry"
                                                :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                                    [self checkNetworkAndStartGraphChain:friendsLVCtl];
                                                }];
    } else {
        [self initiateGraphAPIRequest:nil :friendsLVCtl];
    }
}

// Return either the number of elements in the sorted dataSourceIDs array
// or the filteredDataSourceIndices array, depending on
//  (a) which UITableView requests this, and
//  (b) whether a valid search filter is active
- (NSInteger)numberOfDataRows:(BOOL)forSearchTable {
    NSInteger tableSize;
    NSInteger *tableSizePtr = &tableSize;
    dispatch_sync(self.dataAccessQueue, ^() {
        if((forSearchTable) && (self.filteredDataSourceIndices != nil)) {
            *tableSizePtr = [self.filteredDataSourceIndices count];
        } else {
            *tableSizePtr = [self.dataSourceIDs count];
        }
    });
    return tableSize;
}

// Create a copy of the friend data to decouple it from the synchronized data structures.
// We will reload the table as necessary after changes have been completed.
- (WVFacebookFriend *)copyOfFriendAtRow:(BOOL)forSearchTable :(NSInteger)row {
    __block WVFacebookFriend *newFBFriend;
    dispatch_sync(self.dataAccessQueue, ^() {
        if((forSearchTable) && (self.filteredDataSourceIndices != nil)) {
            if((row >= 0) && (row < [self.filteredDataSourceIndices count])) {
                NSInteger indexToUse = [self.filteredDataSourceIndices[row] unsignedIntegerValue];
                NSString *lookupID = self.dataSourceIDs[indexToUse];
                WVFacebookFriend *fbfriend = self.friendDataDict[lookupID];
                newFBFriend = [WVFacebookFriend newCopyOfFriend:fbfriend];
            }
        } else if((row >= 0) && (row < [self.dataSourceIDs count])) {
                NSString *lookupID = self.dataSourceIDs[row];
                WVFacebookFriend *fbfriend = self.friendDataDict[lookupID];
                newFBFriend = [WVFacebookFriend newCopyOfFriend:fbfriend];
        }
    });
    return newFBFriend;
}


// Generate the next Facebook Graph API request in the chain.
// A nil responseDict generates the initial request, otherwise
// use nextPagingURLFromResponseDict: to generate the request
// from the paging info in the dictionary.
- (NSString *)generateGraphAPIRequestStringFromLastResponse:(NSDictionary *)responseDict {
    if(responseDict == nil) {
        return [NSString stringWithFormat:@"%@%@%@%@", WVconst_initialGraphFriendsRequestURL,
                WVconst_accessTokenString, self.authToken, WVconst_fieldsString];
    }
    return [self nextPagingURLFromResponseDict:responseDict];
}


// NOTE:  This is always called within a dispatch_sync - do NOT put another sync layer in here.
// Filter a set or subset of names using a filter string.
// If starting array is nil, create a new index array from the full dataSourceIDs array.
// Otherwise, create a new index array into the dataSourceIDs array using the starting index array.
- (NSArray *)filterNameArrayBySubstring:(NSArray *)startingArray :(NSString *)filter {
    NSMutableArray *filteredIndicesArray;
    NSString *lcfilter = [filter lowercaseString];
    if(startingArray != nil) {
        NSUInteger nameIndexCount = [startingArray count];
        filteredIndicesArray = [NSMutableArray arrayWithCapacity:nameIndexCount];
        for (NSUInteger idx = 0; idx < nameIndexCount; idx++) {
            NSUInteger idxIntoNames = [startingArray[idx] unsignedLongValue];
            WVFacebookFriend *fbfriend = self.friendDataDict[self.dataSourceIDs[idxIntoNames]];
            if([WVUtilityFunctions stringHasSubstring:[[fbfriend name] lowercaseString]
                                                     :lcfilter]) {
                [filteredIndicesArray addObject:startingArray[idx]];
            }
        }
    } else {
        NSUInteger nameIndexCount = [self.dataSourceIDs count];
        filteredIndicesArray = [NSMutableArray arrayWithCapacity:nameIndexCount];
        for (NSUInteger idx = 0; idx < nameIndexCount; idx++) {
            WVFacebookFriend *fbfriend = self.friendDataDict[self.dataSourceIDs[idx]];
            if([WVUtilityFunctions stringHasSubstring:[[fbfriend name] lowercaseString]
                                                     :lcfilter]) {
                [filteredIndicesArray addObject:[NSNumber numberWithUnsignedInteger:idx]];
            }
        }
    }
    return filteredIndicesArray;
}

// On any change to the search bar filter string,
// look for a cached index array for the filter string.
// Keep stripping the string until we find a cached index array.
// Create and cache a new filtered index array from the
// retrieved index array, or start from the full dataSourceIDs
// array if no cached search results exist.
- (void)searchBarTextChanged:(NSString *)searchText {
    dispatch_async(self.dataAccessQueue, ^() {
        if([searchText isEqualToString:@""]) {
            self.filteredDataSourceIndices = nil;   // start with full dataSourceIDs
            return;
        }
    
        NSString *lcFS = [searchText lowercaseString];
        if(self.searchesAreInvalid) {               // clean out dictionary if data changed
            self.nameSearches = [NSMutableDictionary dictionaryWithCapacity:20];
            self.searchesAreInvalid = NO;
        }

        NSArray *cachedSearch = nil;
        NSMutableString *cacheTestString = [NSMutableString stringWithString:lcFS];
        while([cacheTestString length] > 0) {       // strip away characters until none are left
            NSArray *thisSearchLookup = self.nameSearches[cacheTestString];
            if(thisSearchLookup != nil) {           // on a match, we have cached search results
                cachedSearch = thisSearchLookup;
                break;
            } else {                                // strip last character and look again
                NSRange deletionRange;
                deletionRange.length = 1;
                deletionRange.location = [cacheTestString length] - 1;
                [cacheTestString deleteCharactersInRange:deletionRange];
            }
        }
        NSArray *newFilter = nil;
        if(cachedSearch != nil) {                           // found a cached search
            if([lcFS isEqualToString:cacheTestString]) {    // use cache if exact match
                self.filteredDataSourceIndices = cachedSearch;
                return;
            }                                               // get new filter starting with cached search
            newFilter = [self filterNameArrayBySubstring:cachedSearch :lcFS];
        } else {                                            // no match, filter starting with full ID list
            newFilter = [self filterNameArrayBySubstring:nil :lcFS];
        }
        self.nameSearches[lcFS] = newFilter;                // cache new filter
        self.filteredDataSourceIndices = newFilter;         // set filter property to new filter
    });
}

// Safely update all data source lists from latest Facebook data fetch.
// Update the table views.
- (void)updateDataSourceLists:(WVFriendsListViewController *)friendsListVC {
    dispatch_sync(self.dataAccessQueue, ^() {
        if(self.dataUpdatedSincePull) {
            self.dataSourceIDs = [self sortIDsByNames:[self.friendDataDict allKeys]];
            self.dataUpdatedSincePull = NO;
            self.searchesAreInvalid = YES;
        }
    });
    [friendsListVC.tableView reloadData];
    [[friendsListVC.searchCtl searchResultsTableView] reloadData];
}


// NOTE:  This is called repeatedly inside a dispatch_sync for the dataAccessQueue
//        to ensure queued access to friendDataDict.  Do NOT layer another dispatch block in here.
// Sort IDs in an array (usually the dataSourceIDs array) based on the names of the
// WVFacebookFriend objects stored in self.friendDataDict[id1] and self.friendDataDict[id2].
- (NSArray *)sortIDsByNames:(NSArray *)idList {
    NSArray *newArray = [idList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)[[(WVFacebookFriend *)(self.friendDataDict[obj1]) name] lowercaseString]
                compare:(NSString *)[[(WVFacebookFriend *)(self.friendDataDict[obj2]) name] lowercaseString]];
    }];
    return newArray;
}

// Wait for all executing blocks in the dispatch queue to finish, then update
// all data source lists.  This is used for a final update after the last paged
// Facebook Graph API response.
- (void)waitForGraphRequestsAndUpdateLists:(WVFriendsListViewController *)friendsListVC {
    dispatch_async(dispatch_get_main_queue(), ^() {
        dispatch_group_wait(self.dataAccessQueueGroup, DISPATCH_TIME_FOREVER);
        [self updateDataSourceLists:friendsListVC];
    });
}

// Send a Facebook Graph API request based on the previous response, if any.
// The requestString will be empty after the last paged Graph API response.
// The friendsListVC is used to provide access to the table views to request refreshes.
- (void)initiateGraphAPIRequest:(NSDictionary *)responseDict :(WVFriendsListViewController *)friendsListVC {
    NSString *requestString = [self generateGraphAPIRequestStringFromLastResponse:responseDict];
    if(requestString == nil) {      // no more pages to request; wait for finish, then update tables
        [self waitForGraphRequestsAndUpdateLists:friendsListVC];
        return;
    }
    NSURL *url = [NSURL URLWithString:requestString];       // generate URL and request from string
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //    NSLog(@"Attempting to send request %@", request);
    
    // Create new AFNetworking request operation from the request, and request the JSON serializer
    AFHTTPRequestOperation *requestOp = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOp.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [requestOp setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"Successfully retrieved the following from the Graph JSON %@", responseObject);
        BOOL fillResult = [self fillDictsFromResponseDict:responseObject :friendsListVC];
        if(fillResult) { // update lists and chain next request from this response
            [self updateDataSourceLists:friendsListVC];
            [self initiateGraphAPIRequest:responseObject :friendsListVC];
        } else {         // empty the queue, update lists, skip any remaining requests
            [self waitForGraphRequestsAndUpdateLists:friendsListVC];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Look first for data request rejection - probably an authentication error
        // If so, segue back to log in but don't flush cookies
        if([WVUtilityFunctions stringHasSubstring:error.localizedDescription :@"Request failed"]) {
            [self.alertsMgr genericCustomCancelAlert:@"Facebook rejected the data request"
                                                    :@"Your access rights may have expired or been revoked.  You should log in again."
                                                    :@"Refresh Tokens"
                                                    :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                                        friendsListVC.resumingNotRelogging = YES;
                                                        [friendsListVC performSegueWithIdentifier:@"WVListLogoutSegue"
                                                                                           sender:self];
                                                    }];
        } else {  // Otherwise, it's likely a network error, but provide choice to re-authenticate.
                  // If choosing to log in again, don't flush cookies; otherwise, retry Graph API chain
            [self.alertsMgr genericCustomOkCancelAlert:@"Network error"
                                                      :@"Please check your network connection and press Retry to attempt to reload the data.  If the error continues with a valid connection, please try to log in again."
                                                      :@"Log In"  // OK
                                                      :@"Retry"   // Cancel
                                                      :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                                          if(buttonIndex != cancelIndex) {
                                                              friendsListVC.resumingNotRelogging = YES;
                                                              [friendsListVC performSegueWithIdentifier:@"WVListLogoutSegue"
                                                                                                 sender:self];
                                                          } else {
                                                              [self retryAll:friendsListVC];
                                                          }
                                                      }];
        }
        if(VC_LogDebugStatements) {
            NSLog(@"Request in initiateGraphAPIRequest encountered the following error %@", error);
        }
    }];
    
    [requestOp start];
}


// Check if the valid Graph API response indicates an error.
// Return NO if we didn't have one, YES if we did (and opened an alert).
- (BOOL)handleFacebookGraphErrorResponse:(NSDictionary *)responseDict :(WVFriendsListViewController *)friendsListVC {
    NSDictionary *errorDictList = responseDict[WVconst_fbgraph_topErrorKey];
    if(errorDictList == nil) { // no error
        return NO;
    }
    BOOL loginAgain = NO;
    NSString *errorType = errorDictList[WVconst_fbgraph_errorTypeKey];
    if(errorType != nil) {
        if([WVUtilityFunctions stringHasSubstring:errorType :WVconst_fbgraph_oathException]) {
            loginAgain = YES;  // error type indicates a Facebook authentication problem
        }
    }
    if(loginAgain) {
        [self.alertsMgr genericCustomOkCancelAlert:@"Facebook error"
                                                  :@"Facebook returned an authentication exception error.  You should log in again."
                                                  :@"Log in"  // OK
                                                  :@"Retry"   // Cancel
                                                  :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                                      if(buttonIndex != cancelIndex) {
                                                          [friendsListVC performSegueWithIdentifier:@"WVListLogoutSegue"
                                                                                             sender:self];
                                                      } else {
                                                          [self retryAll:friendsListVC];
                                                      }
                                                  }];

    } else {
        [self.alertsMgr genericCustomCancelAlert:@"Facebook error"
                                                :@"Facebook responded with a data error.  Please press Retry to resend the request.  You may need to wait or log in again."
                                                :@"Retry"
                                                :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                                    if(buttonIndex != cancelIndex) {
                                                        [self retryAll:friendsListVC];
                                                    }
                                                }];

    }
    return YES;
}


// Create new WVFacebookFriend objects from the returned Graph API data
// and add them to self.friendDataDict.  Called by fillDictsFromResponseDict:
// from the success block of a completed Graph API request.
// Returns YES if the function was completely successful with no errors.
- (BOOL)createFriendsFromFBFriendDataDictList:(NSArray *)friendDictList {
    // NOTE:  nil case is already checked before we call this function
    NSUInteger friendCount = [friendDictList count];
    BOOL errorOccurred = NO;
    for(NSUInteger fidx = 0; fidx < friendCount; fidx++) {
        NSDictionary *friendInfoDict = friendDictList[fidx];
        if(friendInfoDict != nil) {                                     // have friend data dict
            NSString *fbid = friendInfoDict[WVconst_fbgraph_idKey];     // grab id and name
            NSString *name  = friendInfoDict[WVconst_fbgraph_nameKey];
            if((fbid == nil) || (name == nil)) {
                errorOccurred = YES;                                    // error if either don't exist
                continue;
            }
            // Handle missing picture a little more gracefully.
            // The table cell ignores an empty picture string.
            NSDictionary *pictureDict = friendInfoDict[WVconst_fbgraph_pictureKey];
            NSString *pictureURLString = nil;
            if(pictureDict != nil) {                                    // have picture dict
                NSDictionary *pictureDataDict = pictureDict[WVconst_fbgraph_pictureDataKey];
                if(pictureDataDict != nil) {                            // have picture data dict
                    pictureURLString = pictureDataDict[WVconst_fbgraph_pictureURLKey];  // grab URL
                } else {
                    errorOccurred = YES;
                }
            } else {
                errorOccurred = YES;
            }
            if(pictureURLString == nil) {
                pictureURLString = @"";             // provide empty URL string on error - will skip
            }
            dispatch_group_async(self.dataAccessQueueGroup, self.dataAccessQueue, ^() {
                self.dataUpdatedSincePull = YES;    // mark tables as dirty, add friend object
                self.friendDataDict[fbid] = [[WVFacebookFriend alloc] initWithIdNameAndPicture:fbid
                                                                                              :name
                                                                                              :pictureURLString];
            } );
        } else {
            errorOccurred = YES;
        }
    }
    return (!errorOccurred);    // YES if no errors occurred
}


// Called from the success block of a finished Graph API request.
// Alert for any error, and create WVFacebookFriend objects for all
// friend data in the request response.
- (BOOL)fillDictsFromResponseDict:(NSDictionary *)responseDict :(WVFriendsListViewController *)friendsListVC {
    if(responseDict == nil) {  // this would be very unusual with a successful AFNetworking request response
        if(VC_LogDebugStatements) {
            NSLog(@"In fillDictsFromResponseDict the responseDict is nil.\n");
        }
        return NO;
    }
    if([self handleFacebookGraphErrorResponse:responseDict :friendsListVC]) {
                    // handleFacebookGraphErrorResponse: returns YES if alerting an error
        return NO;  // The function includes an alert dialog.
    }
    
    NSArray *friendDictList = responseDict[WVconst_fbgraph_topDataKey]; // grab friend data from the response
    BOOL errorOccurred;
    if(friendDictList != nil) {
        // createFriendsFromFBFriendDataDictList: returns YES on complete success
        errorOccurred = (![self createFriendsFromFBFriendDataDictList:friendDictList]);
    } else {
        errorOccurred = YES;
    }
    
    // Allow a retry or an option to accept the missing data as is.
    if(errorOccurred) {
        [self.alertsMgr genericCustomOkCancelAlert:@"Missing data"
                                                  :@"The app encountered some unexpected errors while processing the Facebook data.  Some photos or full entries may be missing.  Press Retry to reload data or OK to accept missing data."
                                                  :@"Retry"
                                                  :@"OK"
                                                  :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                                      if(buttonIndex != cancelIndex) {
                                                          [self retryAll:friendsListVC];
                                                      }
                                                  }];
    }
    return YES;
}

// Return the URL string to request the next page of Graph API data.
// Response will be nil if no "next" page exists in the response.
- (NSString *)nextPagingURLFromResponseDict:(NSDictionary *)responseDict {
    if(responseDict != nil) {
        NSDictionary *pagingDict = responseDict[WVconst_fbgraph_pagingKey];
        if(pagingDict != nil) {
            return pagingDict[WVconst_fbgraph_nextPageKey];
        }
    }
    return nil;
}


@end
