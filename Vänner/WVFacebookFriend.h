//
//  WVFacebookFriend.h
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WVFacebookFriend : NSObject

// Store ID, name, and picture URL string
@property (strong, nonatomic) NSString *fbid;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *pictureURLString;

/* newCopyOfFriend:
 Returns:  A new WVFacebookFriend object with new copies of the strings from
           the provided WVFacebookFriend object.
 */
+ (id)newCopyOfFriend:(WVFacebookFriend *)fbFriend;


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

@end
