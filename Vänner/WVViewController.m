//
//  WVViewController.m
//  Vänner
//
//  Created by Jon on 4/19/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#import "WVGlobalDefinitions.h"
#import "WVViewController.h"
#import "WVAppDelegate.h"
#import "WVFriendsListViewController.h"
#import "WVUtilityFunctions.h"
#import "WVAlertsManager.h"
#import "WVFacebookDataManager.h"
#import "AFNetworking.h"

@interface WVViewController ()

@end

@implementation WVViewController

// Return the Facebook log in URL for either the main log in flow
// or the reauthentication log in flow (with the current user).
- (NSString *)createLoginURL:(BOOL)reauth {
    NSString *optParams;
    if(reauth) {
        optParams = WVconst_reauthParam;
    } else {
        optParams = @"";
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@%@", WVconst_loginURLString,
            WVconst_clientIDString, WVconst_appIDString,
            WVconst_redirectString, WVconst_responseTypeString,
            optParams];
}

// On load from NIB, use full flow.
- (void)awakeFromNib {
    _shouldReauth = NO;
}

// NOTE:  viewDidLoad is being called again on a segue from the other controller
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Reset the version label - addresses enhancement issue #2
    [self.versionLabel setText:[WVUtilityFunctions getVersionLabel]];
    
    self.authTokenString = nil;
    self.resubmitCount = 0;
}

// Ensure we have an alerts manager, check the UIWebView, and start the log in process.
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    WVAppDelegate *appDelegate = (WVAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.lastPresentedVC = self;
    self.alertsMgr = [appDelegate alertsMgr];
    if(self.webView == nil) {
        [self.alertsMgr genericAlert:@"Fatal error"
                                    :@"The web view needed to log in did not load.  Please restart the app."
                                    :^(NSInteger cancelButton, NSInteger buttonIndex) {
                                        // can't really do much in this case
                                    }];
    } else {
        self.webView.scalesPageToFit = YES;
        self.webView.delegate = self;
        [self initiateOpeningRequest];
    }
}

// Alert if network is inaccessible, or ask the UIWebView to load the log in URL.
// The alert will call this function again when it is dismissed.
- (void)initiateOpeningRequest {
    if(![AFNetworkReachabilityManager sharedManager].reachable) {
        __weak __typeof(self) weakSelf = self;  // fix for issue #3
        [self.alertsMgr genericCustomCancelAlert:@"Network error"
                                                :@"Please check your connection to WiFi or enable cellular data, then press Retry to continue."
                                                :@"Retry"
                                                :^(NSInteger cancelIndex, NSInteger buttonIndex) {
                                                    [weakSelf initiateOpeningRequest];
                                                }];
        return;
    }
    
    NSURL *loginURL = [NSURL URLWithString:[self createLoginURL:self.shouldReauth]];
    //        NSLog(@"Login URL for web view is %@", loginURL);
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:loginURL]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Provide WVFacebookDataManager with the authentication token and clear this instance's copy.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //    WVFriendsListViewController *dest = [segue destinationViewController];
    WVFacebookDataManager *dataMgr = [(WVAppDelegate *)[[UIApplication sharedApplication] delegate] fbDataMgr];
    dataMgr.authToken = self.authTokenString;
    self.authTokenString = nil;  // clean up to reduce exposure
}

// --------------------------
// -- New custom functions --
// --------------------------


// Allow a load if it is in the known Facebook log in domains.
// Store authentication token on success or alert user with the error.
// Allow the user to choose to follow or to reject a link that will
// leave the log in flow and open an external browser.
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    //    NSLog(@"Intercepted web view request %@", request);
    __block NSURL *requestURL = [request URL];
    if([self allowURLRequest:request]) {
        if([self doesURLRequestSuccessPath:requestURL]) {
            //            NSLog(@"Log in was successful.\n");
            __weak __typeof(self) weakSelf = self;  // fix for issue #3 - being conservative with async dispatch
            if([self getAuthTokenFromSuccessfulRequestURL:requestURL]) {
                dispatch_async(dispatch_get_main_queue(), ^(){ [weakSelf segueWithValidAuthTokens]; });
            } else {
                [self.alertsMgr genericCustomCancelAlert:@"Log in error"
                                                        :@"Could not retrieve authentication tokens with the successful log in.  Please press Retry to restart the log in process."
                                                        :@"Retry"
                                                        :^(NSInteger cancelButton, NSInteger buttonIndex) {
                                                            [weakSelf initiateOpeningRequest];
                                                        }];
            }
        }
        return YES;
    }
    [self.alertsMgr genericOkCancelAlert:@"Leaving log in flow"
                                        :@"Following that link will interrupt the normal log in session and launch a web browser app.  Continue?"
                                        :^(NSInteger cancelButton, NSInteger buttonIndex) {
                                            if(buttonIndex != cancelButton) {
                                                [[UIApplication sharedApplication] openURL:requestURL];
                                            }
                                        }];
    return NO;
}


// Clear the resubmission counter on a successful load.
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.resubmitCount = 0;
}


// Set self.authTokenString and return YES if we find a fragment in the URL
// with 'WVconst_authTokenFieldName="TOKEN"', otherwise return NO.
- (BOOL)getAuthTokenFromSuccessfulRequestURL:(NSURL *)url {
    if(url == nil) {
        return NO;
    }
    NSString *fragmentString = [url fragment];
    NSArray *fragments = [fragmentString componentsSeparatedByString:WVconst_fragmentSeparator];
    NSUInteger fragmentCount = [fragments count];
    for(NSUInteger i = 0; i < fragmentCount; i++) {
        NSArray *subFragments = [fragments[i] componentsSeparatedByString:@"="];
        if([subFragments count] > 1) {
            if([(NSString *)subFragments[0] isEqualToString:WVconst_authTokenFieldName]) {
                self.authTokenString = subFragments[1];
                return YES;
            }
        }
    }
    return NO;
}


// Deny request if it isn't to the expected Facebook domain/path combinations.
- (BOOL)allowURLRequest:(NSURLRequest *)request {
    NSURL *requestURL = [request URL];
    if([self doesURLRequestExpectedDomain:requestURL] &&
       [self doesURLRequestExpectedPath:requestURL]) {
        return YES;
    }
    return NO;
}


// Check if the path of the URL is for the expected full log in path
// or the reauthentication path.
- (BOOL)doesURLRequestLoginForm:(NSURL *)url {
    NSString *path = [url path];
    if([self doesURLRequestExpectedDomain:url]) {
        if([path isEqualToString:WVconst_expectedLoginPath] ||
           [path isEqualToString:WVconst_expectedReauthPath]) {
            return YES;
        }
    }
    return NO;
}

// Check if the path of the URL is for any of the possible paths in
// the log in flow, including log in, reauth, oauth (for extra access
// forms), alternative language, and success.
- (BOOL)doesURLRequestExpectedPath:(NSURL *)url {
    NSString *path = [url path];
    if([path isEqualToString:WVconst_expectedLoginPath] ||
       [path isEqualToString:WVconst_expectedReauthPath] ||
       [WVUtilityFunctions stringHasSubstring:path :WVconst_expectedOauthPath] ||
       [WVUtilityFunctions stringHasSubstring:path :WVconst_expectedLanguagePath] ||
       [path isEqualToString:WVconst_expectedSuccessPath]) {
        return YES;
    }
    return NO;
}

// Check if the URL requests the path we expect on a fully successful log in attempt.
- (BOOL)doesURLRequestSuccessPath:(NSURL *)url {
    NSString *path = [url path];
    if([self doesURLRequestExpectedDomain:url]) {
        //        NSLog(@"test for success with path %@ and expected %@", path, WVconst_expectedSuccessPath);
        return ([path isEqualToString:WVconst_expectedSuccessPath]);
    }
    return NO;
}

// Check if the URL requests a host in the Facebook.com domain.
- (BOOL)doesURLRequestExpectedDomain:(NSURL *)url {
    NSString *host = [url host];
    NSArray *hostStrings = [host componentsSeparatedByString:@"."];
    NSInteger lastString = [hostStrings count];
    if(lastString >= 2) {
        lastString -= 1;
        if([(NSString *)(hostStrings[lastString]) isEqualToString:WVconst_expectedHostDomainExt]) {
            lastString -= 1;
            if([(NSString *)hostStrings[lastString] isEqualToString:WVconst_expectedHostDomainName]) {
                return YES;
            }
        }
    }
    return NO;
}


// Start segue to the other view controller if we have a valid authentication
// token reference.
- (void)segueWithValidAuthTokens {
    if(self.authTokenString != nil) {
        [self performSegueWithIdentifier:segueToFriendsList sender:self];
    }
}


// Ignore benign asynchronous load cancellations (-999).
// Alert and allow retry once resubmission limit has been reached.
// Otherwise, increment resubmission count and ask the UIWebView to
// reload the request.
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(error != nil) {
        // The -999 error code is a cancellation of an asynchronous load.
        // It can happen sometimes on redirects and can be ignored here.
        // The login form is there and can be submitted properly.
        if([error code] == -999) {
            return;
        }
        
        if(self.resubmitCount > WVconst_maxResubmissions) {
            __weak __typeof(self) weakSelf = self;  // fix for issue #3 - avoid self retain cycles
            [self.alertsMgr genericCustomCancelAlert:@"Web page loading error"
                                                    :@"Failed to load Facebook login form data.  Please check your WiFi connection or enable cellular data, then press Retry."
                                                    :@"Retry"
                                                    :^(NSInteger cancelButton, NSInteger buttonIndex) {
                                                        [weakSelf initiateOpeningRequest];
                                                    }];
            if(VC_LogDebugStatements) {
                NSLog(@"Web view error is %@\n", error);
            }
        } else {
            self.resubmitCount += 1;
            [webView stopLoading];
            dispatch_async(dispatch_get_main_queue(), ^(){ [webView reload]; });
        }
    }
}


// OBSOLETE - The code below is being kept for future reference, if needed.
//            These functions were used with JavaScript injection of ID and password
//            into the Facebook form in a hidden UIWebView.
//            Since Facebook requires at least one more acknowledgment from the user
//            to approve access for a new app, this app is using the standard Facebook
//            oauth flow in a visible UIWebView.

/*
- (BOOL)fillInForm {
    //    if(submittedOnce) {
    //        return NO;
    //    }
    
    if(self.webView == nil) {
        NSLog(@"For fillInForm(), the web view is nil.\n");
        return NO;
    }
    
    NSString *nameFillCmd = [self createJSReplacementCmdString:WVconst_emailFieldName
                                                              :[self.fbUserIDField text]];
    NSString *passFillCmd = [self createJSReplacementCmdString:WVconst_passwordFieldName
                                                              :[self.passwordField text]];
    NSString *clickCmd    = [self createJSClickLoginCmdString:WVconst_loginButtonName];
    
    //    NSLog(@"Trying to fill in %@ fields with %@", @"email", nameFillCmd);
    NSString *jsResult = [self.webView stringByEvaluatingJavaScriptFromString:nameFillCmd];
    if(jsResult != nil) {
        //        NSLog(@"Trying to fill in %@ fields with %@", @"pass", passFillCmd);
        jsResult = [self.webView stringByEvaluatingJavaScriptFromString:passFillCmd];
        if(jsResult != nil) {
            //            NSLog(@"Trying to click %@ button with %@", @"login", clickCmd);
            jsResult = [self.webView stringByEvaluatingJavaScriptFromString:clickCmd];
            if(jsResult != nil) {
                //                submittedOnce = YES;
                return YES;
            }
        }
    }
    NSLog(@"JS action failed.\n");
    return NO;
}


- (NSString *)createJSReplacementCmdString:(NSString *)fieldName :(NSString *)fieldValue {
    NSString *jsCmdString = [NSString stringWithFormat:@"var inputFields = document.querySelectorAll(\"input[name='%@']\"); \
                             for (var i = inputFields.length >>> 0; i--;) { inputFields[i].value = '%@';}", fieldName, fieldValue];
    return jsCmdString;
}

- (NSString *)createJSClickLoginCmdString:(NSString *)buttonName {
    NSString *jsCmdString = [NSString stringWithFormat:@"document.getElementsByName('%@')[0].click();", buttonName];
    return jsCmdString;
}


- (BOOL)errorWithLoginFieldLengths:(NSString *)s1 :(NSString *)s2 {
    if(([s1 length] == 0) || ([s2 length] == 0)) {
        [self.alertsMgr genericAlert:@"Missing info"
                                    :@"Both UserID and password must not be blank."
                                    :^(NSInteger cancelButton, NSInteger buttonIndex) {
                                        // don't do anything in this case - allow user to change fields
                                    }];
        return YES;
    }
    return NO;
}

- (IBAction)signInTouched:(id)sender {
    // hide keyboard by having the fields end any activity
    [self.fbUserIDField endEditing:YES];
    [self.passwordField endEditing:YES];
    
    NSString    *idString, *pwString;
    idString = [self.fbUserIDField text];
    pwString = [self.passwordField text];
    // both fields must have content to proceed with sign in; else, display error dialog
    if([self errorWithLoginFieldLengths:idString :pwString]) {
        return;
    }
    
    if(self.webView != nil) {
        if(self.webView.loading) {
            [self.alertsMgr genericAlert:@"Try again..."
                                        :@"The connection to Facebook seems to be slow."
                                        :^(NSInteger cancelButton, NSInteger buttonIndex) {
                                            // don't do anything in this case - user will try to press button again
                                        }];
            return;
        }
        if([self doesURLRequestLoginForm:[self.webView.request URL]]) {
            [self fillInForm];
        }
    }
    
    // sign in is complete, perform segue to friend list view controller
    // [self performSegueWithIdentifier:segueToFriendsList sender:self];
}
*/

@end
