//
//  WVUtilityFunctions.h
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WVUtilityFunctions : NSObject

/* stringHasSubstring:
 Returns:  YES if mainString contains subString.  NO, otherwise.
 */
+ (BOOL)stringHasSubstring:(NSString *)mainString :(NSString *)subString;

/* getVersionLabel
 Returns:  NSString object ref with app version string.  Numbers have X.Y placeholders
 if the bundle version cannot be retrieved from the main bundle.
 */
+ (NSString *)getVersionLabel;

@end
