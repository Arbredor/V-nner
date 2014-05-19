//
//  WVViewController.h
//  Vänner
//
//  Created by Jon on 4/19/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WVAlertsManager;

@interface WVViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic) NSUInteger resubmitCount;

// Keep reference to the alerts manager for convenience
@property (strong, nonatomic) WVAlertsManager *alertsMgr;

// Keep weak reference to child UIWebView
@property (weak, nonatomic) IBOutlet UIWebView   *webView;

// Keep weak reference to child UILabel for updating version
@property (weak, nonatomic) IBOutlet UILabel    *versionLabel;

// Temporarily store the authentication token string returned
// on a successful log in.
@property (strong, nonatomic) NSString    *authTokenString;

// Hold a flag to optionally use the reauthentication Facebook
// log in flow.  That flow assumes the user is the same and just
// asks for the password.
// - NOTE:  The current usage model for the app doesn't need it.
@property (nonatomic) BOOL shouldReauth;

/* createLoginURL:
 Returns:  A new string for a Facebook log in URL request.
 Optionally adds the reauthentication param string
 for Facebook's flow requesting a password from the
 current user.
 */
- (NSString *)createLoginURL:(BOOL)reauth;


/* awakeFromNib does the following:
 Sets shouldReauth to NO so the UIWebView uses the main log in flow.
 */
- (void)awakeFromNib;


/* viewDidLoad does the following:
 Clears the authentication token string and resets the resubmission counter.
 */
- (void)viewDidLoad;


/* viewDidAppear: does the following:
 (1) Refreshes the reference to the alerts manager
 (2) Saves a reference to this view controller as the most recently displayed
 view controller in the app delegate
 (3) Alerts the user on an unlikely error with a missing UIWebView,
 or sets up web view properties and calls initiateOpeningRequest
 to start the log in process
 */
- (void)viewDidAppear:(BOOL)animated;


/* initiateOpeningRequest does the following:
 (1) Checks if the network is reachable and alerts the user if it isn't
 (2) If the network is available, creates the log in URL request and asks the
 UIWebView to load it.
 */
- (void)initiateOpeningRequest;


/* prepareForSegue: does the following:
 (1) Gets a reference to the WVFacebookDataManager and stores the successful
 authentication token in it.
 (2) Clears out the instance's copy of the authentication token.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;


/* webView:shouldStartLoadWithRequest: does the following:
 (1) Calls allowURLRequest: to examine the requested URL.  If the URL
 is in the known Facebook log in domains, allows the load to proceed.
 Otherwise, alerts that following the link will open an external browser.
 Allows OK and cancel.
 (2) If the URL is allowed and it isn't for the successful authentication path,
 proceeds with load.
 (3) If the URL is allowed, it is for the successful authentication path,
 and it has a valid authentication token string in it,
 asynchronously dispatches a segue on the main queue with segueWithValidAuthTokens.
 Proceeds with load.
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;


/* getAuthTokenFromSuccessfulRequestURL: does the following:
 (1) Splits a valid URL into fragments separated by the usual field separator
 (2) Sets the instance's authTokenString when a fragment separated with "="
 begins with the auth token string and ends with another string.
 Returns:  YES if it parsed an authentication token from the URL, otherwise NO.
 */
- (BOOL)getAuthTokenFromSuccessfulRequestURL:(NSURL *)url;


/* webViewDidFinishLoad: does the following:
 Clears the resubmission counter.
 */
- (void)webViewDidFinishLoad:(UIWebView *)webView;


/* allowURLRequest:
 Returns:  YES if the URL requests an expected domain/path combo for
 the Facebook log in flow.  NO, otherwise.
 */
- (BOOL)allowURLRequest:(NSURLRequest *)request;


/* doesURLRequestLoginForm:
 Returns:  YES if the URL requests an expected path in the Facebook
 log in flow or reauthentication flow.  NO, otherwise.
 */
- (BOOL)doesURLRequestLoginForm:(NSURL *)url;


/* doesURLRequestExpectedPath:
 Returns:  YES if the URL requests an expected path in the log in flow,
 reauth flow, oauth flow (for extra access forms), alternative
 language flows, and the success flow.  NO, otherwise.
 */
- (BOOL)doesURLRequestExpectedPath:(NSURL *)url;


/* doesURLRequestSuccessPath:
 Returns:  YES if the URL requests the path we expect to see on
 a fully successful log in attempt.
 */
- (BOOL)doesURLRequestSuccessPath:(NSURL *)url;


/* doesURLRequestExpectedDomain:
 Returns:  YES if the URL requests a host in the facebook.com domain.
 NO, otherwise.
 */
- (BOOL)doesURLRequestExpectedDomain:(NSURL *)url;


/* segueWithValidAuthTokens does the following:
 Segues to the friends list view controller if we have a valid authentication
 token string reference.  This instance copies its reference to the other controller
 inside prepareForSegue: and then deletes its copy.
 */
- (void)segueWithValidAuthTokens;


/* webView: does the following:
 (1) On a valid error, returns immediately if the error is type -999,
 a cancellation of an asynchronous load which can be ignored.
 The login form exists and can be submitted properly.
 (2) Otherwise, if the resubmit counter passed its limit, alert the
 user of a problem and allow him to retry.
 (3) If the resubmit counter is still below its limit, increment it
 and ask the UIWebView to reload its request.
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;

@end
