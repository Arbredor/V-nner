//
//  WVAlertsManager.m
//  Vänner
//
//  Created by Jon on 4/25/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import "WVAlertsManager.h"

@implementation WVAlertsManager

// Create the lookup dictionary and the dispatch queue to protect the ID counter.
// Set initial ID to 1.
- (id)init {
    self = [super init];
    if(self != nil) {
        _alertLookup = [NSMutableDictionary dictionaryWithCapacity:10];
        _alertID_queue = dispatch_queue_create("com.spd.wvAlertIDqueue", NULL);
        dispatch_sync(_alertID_queue, ^() {
            _nextAlertID = 1;
        });
    }
    return self;
}

- (NSInteger)createAlertID {
    __block NSInteger nid;
    dispatch_sync(self.alertID_queue, ^() {
        // synchronously post-increment the ID counter
        nid = self.nextAlertID++;
    });
    return nid;
}

// On dismissal of a valid UIAlertView, retrieve and call the onFinish block.
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView != nil) {
        NSInteger tag = [alertView tag];                        // get the tag
        NSNumber *alertKey = [NSNumber numberWithInteger:tag];  // create the lookup key
        void (^onFinish)(NSInteger, NSInteger);
        onFinish = self.alertLookup[alertKey];                  // get the onFinish block
        [self.alertLookup removeObjectForKey:alertKey];         // remove the used key
        if(onFinish != nil) {
            onFinish(alertView.cancelButtonIndex, buttonIndex); // call the block
        }
    }
}


// Create and display an "OK" alert with a return block.
- (void)genericAlert:(NSString *)title :(NSString *)message :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    alert.tag = [self createAlertID];
    self.alertLookup[[NSNumber numberWithInteger:alert.tag]] = onFinish;
    [alert show];
}

// Create and display an "Okay/Cancel" alert with a return block.
- (void)genericOkCancelAlert:(NSString *)title :(NSString *)message :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    alert.tag = [self createAlertID];
    self.alertLookup[[NSNumber numberWithInteger:alert.tag]] = onFinish;
    [alert show];
}

// Create and display a customizable single-button alert with a return block.
- (void)genericCustomCancelAlert:(NSString *)title :(NSString *)message :(NSString *)cancelTitle :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:cancelTitle
                                          otherButtonTitles:nil, nil];
    alert.tag = [self createAlertID];
    self.alertLookup[[NSNumber numberWithInteger:alert.tag]] = onFinish;
    [alert show];
}

// Create and display a customizable double-button alert with a return block.
- (void)genericCustomOkCancelAlert:(NSString *)title :(NSString *)message :(NSString *)okTitle :(NSString *)cancelTitle :(void (^)(NSInteger cancelIndex, NSInteger buttonIndex))onFinish {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:cancelTitle
                                          otherButtonTitles:okTitle, nil];
    alert.tag = [self createAlertID];
    self.alertLookup[[NSNumber numberWithInteger:alert.tag]] = onFinish;
    [alert show];
}

@end
