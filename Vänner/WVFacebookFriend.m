//
//  WVFacebookFriend.m
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import "WVAppDelegate.h"
#import "WVAlertsManager.h"
#import "WVGlobalDefinitions.h"
#import "WVFacebookFriend.h"
#import "WVFriendsListViewController.h"
#import "UIImageView+AFNetworking.h"

@implementation WVFacebookFriend

// Initialize a WVFacebookFriend with no provided references
- (id)init {
    return [self initWithIdNameAndPicture:nil :nil :nil];  // part of bug fix for issue #1 (move [super init])
}

// Initialize a WVFacebookFriend with the provided ID, name, and picture URL string references
- (id)initWithIdNameAndPicture:(NSString *)uid :(NSString *)uname :(NSString *)urlString {
    self = [super init];  // part of bug fix for issue #1 (move [super init] from init())
    if(self != nil) {
        _fbid = uid;
        _name = uname;
        _pictureURLString = urlString;
        _pictureRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        _tempImageView = nil;
        [self cacheImage:_pictureRequest :nil :nil :0];
    }
    return self;
}

// Cache the friend's image if it has not already been cached or it has been released from the cache
- (void)cacheImage:(NSURLRequest *)request :(WVFriendsListViewController *)receiver :(UITableView *)view :(NSInteger)forRow {
    if([[UIImageView sharedImageCache] cachedImageForRequest:request] != nil) {
        return;  // return if the AFNetworking image cache already has an image for this request
    }
    // Create a temporary UIImageView and use the AFNetworking extensions to get the image (and cache it)
    _tempImageView = [[UIImageView alloc] initWithImage:[WVFacebookFriend placeholderImage]];
    [self requestImageWithAFNetworking:_pictureRequest :receiver :view :forRow];  // row used to determine if table view should reload
}

// Return either the friend's cached image or a placeholder.  If the image is not in the cache,
// request that it be cached.
- (UIImage *)picture:(WVFriendsListViewController *)receiver :(UITableView *)view :(NSInteger)forRow {
    NSURLRequest *request = self.pictureRequest;
    UIImage *image = [[UIImageView sharedImageCache] cachedImageForRequest:request];
    if(image == nil) {
        [self cacheImage:request :receiver :view :forRow];  // previous matching AFNetworking requests, if any, will be cancelled
        image = [WVFacebookFriend placeholderImage];
    }
    return image;
}


// Use AFNetworking UIImageView extensions to asynchronously load the friend's picture
// into a temporary UIImageView (also placing it in the AFNetworking image cache).
// On success, remove the reference to the temporary UIImageView.
- (void)requestImageWithAFNetworking:(NSURLRequest *)request :(WVFriendsListViewController *)receiver :(UITableView *)view :(NSInteger)forRow {
    // doing the weak/strong dance because the view controller and the table view reference the friend objects already
    // none of these objects should disappear while we are requesting images
    __weak __typeof(self) weakSelf = self;
    __weak WVFriendsListViewController *weakFLVC = receiver;
    __weak UITableView *weakView = view;
    [_tempImageView setImageWithURLRequest:request
                          placeholderImage:[WVFacebookFriend placeholderImage]
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       __strong __typeof(weakSelf) strongSelf = weakSelf;
                                       __strong WVFriendsListViewController *strongFLVC = weakFLVC;
                                       __strong UITableView *strongView = weakView;
                                       if(strongFLVC != nil) {
                                           // request view to reload the row data if the row is visible
                                           [strongFLVC pictureCachedForRow:strongView :forRow];
                                       }
                                       // image should now be cached - remove the saved reference
                                      [strongSelf setTempImageView:nil];
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       if(error.code == -999) {  // re-request interrupted async loads - fix for issue #4
                                           // request again and return immediately (don't recurse rest of function)
                                           dispatch_async(dispatch_get_main_queue(), ^() {
                                               __strong __typeof(weakSelf) strongSelf = weakSelf;
                                               __strong WVFriendsListViewController *strongFLVC = weakFLVC;
                                               __strong UITableView *strongView = weakView;
                                               [strongSelf requestImageWithAFNetworking:request :strongFLVC :strongView :forRow];
                                           });
                                           return;
                                       } // otherwise, open an image error alert, if one is not already visible
                                       WVAlertsManager *alertsManager = [(WVAppDelegate *)([[UIApplication sharedApplication] delegate]) alertsMgr];
                                       __weak WVAlertsManager *weakAlertsManager = alertsManager;
                                       [alertsManager imageAlertIfNoneVisible:@"Image load error"
                                                                             :@"At least one image failed to load.  Press Retry to refresh the data or OK to accept missing images."
                                                                             :@"Retry"
                                                                             :@"OK"
                                                                             :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                                                                 __strong WVFriendsListViewController *strongFLVC = weakFLVC;
                                                                                 __strong WVAlertsManager *strongAlertsManager = weakAlertsManager;
                                                                                 if(buttonIndex != cancelIndex) {
                                                                                     if(strongFLVC != nil) {
                                                                                         [strongFLVC retryAll];
                                                                                     }
                                                                                 }
                                                                                 [strongAlertsManager imageAlertDismissed];
                                                                             }];
                                   }];
}

// Create a new copy with fresh strings
+ (id)newCopyOfFriend:(WVFacebookFriend *)fbFriend {
    return [[WVFacebookFriend alloc] initWithIdNameAndPicture:[NSString stringWithString:[fbFriend fbid]]
                                                             :[NSString stringWithString:[fbFriend name]]
                                                             :[NSString stringWithString:[fbFriend pictureURLString]]];
}

// Return a UIImage object with the default size friend's image placeholder.
+ (UIImage *)placeholderImage {
    static UIImage *_placeholderImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _placeholderImage = [UIImage imageNamed:WVconst_placeholderImageFile];
    });
    return _placeholderImage;
}

@end
