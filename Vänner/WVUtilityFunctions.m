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

// Returns the version string for the app using the version info stored in the main bundle.
// The numbers have placeholders X.Y if the version info can't be retrieved.
// -- Addresses enhancement issue #2.
+ (NSString *)getVersionLabel {
    NSBundle *appBundle = [NSBundle mainBundle];
    if(appBundle) {
        NSString *versionString = [appBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        if(versionString) {
            return [NSString stringWithFormat:@"Vänner v%@", versionString];
        }
    }
    return @"Vänner vX.Y";
}



@end
