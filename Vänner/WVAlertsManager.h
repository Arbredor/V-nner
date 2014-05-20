//
//  WVAlertsManager.h
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WVAlertsManager : NSObject <UIAlertViewDelegate>

// Alert ID lookup table and alert ID counter
@property (strong, nonatomic) NSMutableDictionary *alertLookup;
@property (nonatomic) NSInteger nextAlertID;
@property (nonatomic) BOOL imageAlertShown;

// Dispatch queue to protect access to the alert ID counter and image alert boolean
@property (strong, nonatomic) dispatch_queue_t alertID_queue;

/*
 init does the following:
 // (1) Creates a small lookup dictionary in alertLookup for UIAlertViews
 // (2) Creates the sync dispatch queue to protect the ID counter (nextAlertID) for UIAlertView tags
 // (3) Sets the ID counter value to 1
 Returns: The object id on success; nil on failure.
 */
- (id)init;

/*
 createAlertID does the following:
 (1) Synchronously returns and increments the ID counter
 Returns:  NSInteger value of the ID counter prior to increment.
 */
- (NSInteger)createAlertID;

/*
 alertView:didDismissWithButtonIndex: does the following:
 (1) Grabs the tag from a valid alertView parameter
 (2) Looks up the tag in self.alertLookup for the block to
     execute when the alert is dismissed
 (3) Removes the tag from self.alertLookup
 (4) Executes the block, passing it the alertView.cancelButtonIndex
     and the touched buttonIndex
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

/*
 genericAlert:
 Generates and displays an UIAlertView with a single "OK" button given
 a title, a message, and a block to execute when the view is dismissed.
 */
- (void)genericAlert:(NSString *)title :(NSString *)message :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish;

/*
 genericOkCancelAlert:
 Generates and displays an UIAlertView with a "Cancel" and an "OK" button given
 a title, a message, and a block to execute when the view is dismissed.
 */
- (void)genericOkCancelAlert:(NSString *)title :(NSString *)message :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish;

/*
 genericCustomCancelAlert:
 Generates and displays an UIAlertView with a single button given
 a title, a message, a cancel button title, and a block to execute
 when the view is dismissed.
 */
- (void)genericCustomCancelAlert:(NSString *)title :(NSString *)message :(NSString *)cancelTitle :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish;

/*
 genericCustomOkCancelAlert:
 Generates and displays an UIAlertView with two buttons given
 a title, a message, an OK button title, a cancel button title,
 and a block to execute when the view is dismissed.
 */
- (void)genericCustomOkCancelAlert:(NSString *)title :(NSString *)message :(NSString *)okTitle :(NSString *)cancelTitle :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish;

/*
 imageAlertIfNoneVisible:
 Checks and sets the imageAlertShown property.  If the property was
 previously clear, the function calls the genericCustomOKCancelAlert:
 function with the provided arguments.  NOTE:  The completion function
 should call [alertsManager imageAlertDismissed] to clear the property.
 */
- (void)imageAlertIfNoneVisible:(NSString *)title :(NSString *)message :(NSString *)okTitle :(NSString *)cancelTitle :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish;

/*
 imageAlertDismissed
 Clears the imageAlertShown property.  Completion (onFinish) blocks provided
 to imageAlertIfNoneVisible should call this function when the alert is dismissed.
 */
- (void)imageAlertDismissed;


@end
