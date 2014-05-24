//
//  WVFacebookFriend.h
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WVFriendsListViewController;

@interface WVFacebookFriend : NSObject

// Store ID, name, and picture URL string
@property (strong, nonatomic) NSString *fbid;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *pictureURLString;
@property (strong, nonatomic) NSURLRequest *pictureRequest;

// Temporary image view to use for caching images with AFNetworking
@property (strong, nonatomic) UIImageView *tempImageView;

// Track if an image caching request is in progress
@property (strong, nonatomic) dispatch_queue_t requestTrackingQueue;
@property (nonatomic) BOOL requestInProgress;

/* newCopyOfFriend:
 Returns:  A new WVFacebookFriend object with new copies of the strings from
           the provided WVFacebookFriend object.
 */
+ (id)newCopyOfFriend:(WVFacebookFriend *)fbFriend;

/* placeholderImage
 Returns:  A reference to a UIImage object with the default size friend's
           image placeholder.  The image is created once and held by the class.
 */
+ (UIImage *)placeholderImage;


/* init:
 Returns:  The result of initWithIdNameAndPicture with nil string references,
           or nil if the object couldn't be created properly.
 */
- (id)init;


/* initWithIdNameAndPicture:
 Returns:  A new WVFacebookFriend object initialized with the given string
           references, or nil if the object couldn't be created properly.
 */
- (id)initWithIdNameAndPicture:(NSString *)uid :(NSString *)uname :(NSString *)urlString;


/* requestImageWithAFNetworking:
 Uses AFNetworking UIImageView extensions to asynchronously load the friend's
 picture into a temporary UIImageView (also placing it in the AFNetworking image
 cache).  On success, asks a non-nil receiver and view to reload the row data if the
 row is visible, and removes the reference to the temporary UIImageView.
 */
- (void)requestImageWithAFNetworking:(NSURLRequest *)request :(WVFriendsListViewController *)receiver :(UITableView *)view :(NSInteger)forRow;

/* cacheImage:
 Caches the friend's image if it has not already been cached or it has
 been released from the AFNetworking image cache.  This function creates
 a temporary UIImageView and calls requestImageWithAFNetworking: using
 the provided arguments if the image is not in the cache.  Nil arguments
 for the receiver and view are fine for initial caching.
 */
- (void)cacheImage:(NSURLRequest *)request :(WVFriendsListViewController *)receiver :(UITableView *)view :(NSInteger)forRow;

/* picture:
 Requests this friend's picture from the cache and returns it if it is there.
 If the picture is not in the cache, it calls cacheImage: with the provided
 arguments and returns the placeholder image.
 */
- (UIImage *)picture:(WVFriendsListViewController *)receiver :(UITableView *)view :(NSInteger)forRow;

@end
