//
//  WVFacebookFriend.m
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import "WVFacebookFriend.h"

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
    }
    return self;
}

// Create a new copy with fresh strings
+ (id)newCopyOfFriend:(WVFacebookFriend *)fbFriend {
    return [[WVFacebookFriend alloc] initWithIdNameAndPicture:[NSString stringWithString:[fbFriend fbid]]
                                                             :[NSString stringWithString:[fbFriend name]]
                                                             :[NSString stringWithString:[fbFriend pictureURLString]]];
}

@end
