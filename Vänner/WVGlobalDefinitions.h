//
//  WVGlobalDefinitions.h
//  Vänner
//
//  Created by Jon on 4/21/14.
//  Copyright (c) 2014 SPD. All rights reserved.
//

#ifndef Va_nner_WVGlobalDefinitions_h
#define Va_nner_WVGlobalDefinitions_h

// Turn extra debug NSLog statements on or off
#define VC_LogDebugStatements YES

// --- String constants used in WVAppDelegate (and WVViewController) ---
// Segue ID used for the transition from list to login
static NSString * const segueToFriendsList = @"WVLoginToListSegue";

// --- Constants used in WVViewController ---

// Resubmission count for errors
static NSUInteger const WVconst_maxResubmissions = 3;

// URL hosts and paths in the Facebook auth flow
static NSString * const WVconst_expectedHostDomainName = @"facebook";
static NSString * const WVconst_expectedHostDomainExt  = @"com";
static NSString * const WVconst_expectedOauthPath = @"/dialog/oauth";
static NSString * const WVconst_expectedLoginPath = @"/login.php";
static NSString * const WVconst_expectedReauthPath = @"/login/reauth.php";
static NSString * const WVconst_expectedSuccessPath = @"/connect/login_success.html";
static NSString * const WVconst_reauthParameter = @"auth_type=reauthenticate";
static NSString * const WVconst_expectedLanguagePath = @"/language.php";

// Facebook auth form labels
// name="email"
// name="pass"
// name="login" (button)
static NSString * const WVconst_emailFieldName = @"email";
static NSString * const WVconst_passwordFieldName = @"pass";
static NSString * const WVconst_loginButtonName = @"login";

// Auth token parsing
static NSString * const WVconst_fragmentSeparator = @"&";
static NSString * const WVconst_authTokenFieldName = @"access_token";

// Strings for the initial Facebook https login request
static NSString * const WVconst_appIDString    = @"613989702022607";  // the client ID for the app
static NSString * const WVconst_loginURLString = @"https://www.facebook.com/dialog/oauth?";
static NSString * const WVconst_clientIDString = @"client_id=";
static NSString * const WVconst_redirectString = @"&redirect_uri=https://www.facebook.com/connect/login_success.html";
static NSString * const WVconst_responseTypeString = @"&response_type=token";
static NSString * const WVconst_reauthParam = @"&auth_type=reauthenticate";


// --- String constants used in WVFacebookDataManager ---
// GET example for querying graph API
// https:
//  //graph.facebook.com/me/friends?fields=id,first_name,last_name,picture.width(50).height(50)

// String constants to generate FB Graph API request URL
static NSString * const WVconst_initialGraphFriendsRequestURL = @"https://graph.facebook.com/me/friends";
static NSString * const WVconst_accessTokenString = @"?access_token=";
static NSString * const WVconst_fieldsString = @"&fields=id,name,picture.width(50).height(50)";

// String constants for keys into FB Graph API return dictionary
static NSString * const WVconst_fbgraph_topErrorKey = @"error";
static NSString * const WVconst_fbgraph_errorTypeKey = @"type";
static NSString * const WVconst_fbgraph_errorMessageKey = @"message";
static NSString * const WVconst_fbgraph_errorCodeKey = @"code";
static NSString * const WVconst_fbgraph_oathException = @"OAuthException";

// String constants for keys into FB Graph API friend data
static NSString * const WVconst_fbgraph_topDataKey = @"data";
static NSString * const WVconst_fbgraph_pagingKey = @"paging";
static NSString * const WVconst_fbgraph_nextPageKey = @"next";
static NSString * const WVconst_fbgraph_pictureKey = @"picture";
static NSString * const WVconst_fbgraph_pictureDataKey = @"data";
static NSString * const WVconst_fbgraph_pictureURLKey = @"url";
static NSString * const WVconst_fbgraph_idKey = @"id";
static NSString * const WVconst_fbgraph_nameKey = @"name";


// --- Constants used in WVFriendsListViewController ---

// Segue ID used for the transition to the login view controller
static NSString * const segueToLogin = @"WVListLogoutSegue";

// Cell ID used for the table's Cell Reuse ID
static NSString * const WVTableViewCellIdentifier = @"WVTableViewCell";

// String to match within cookie domain - used for removing cookies to reauth Facebook
static NSString * const WVconst_cookieDomainFacebook = @"facebook.com";



#endif
