//
//  WVUtilityFunctions.m
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import "WVUtilityFunctions.h"

@implementation WVUtilityFunctions


// Return YES if mainString contains subString.
+ (BOOL)stringHasSubstring:(NSString *)mainString :(NSString *)subString {
    NSRange rangeFound = [mainString rangeOfString:subString];
    return (rangeFound.location != NSNotFound);
}


@end
