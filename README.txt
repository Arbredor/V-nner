
README_Vanner.txt for Vänner iPhone app

-----
Edited:  Tuesday, 20 May 2014
• Reopened and fixed bug issue #5:  AFNetworking and UIImageView async image loading race condition when scrolling quickly.

Details:  Increasing the size of the table cell prototype queue did not completely solve the problem.  Unless the queue is very large, fast scrolling still exposes recycled cell references, so asynchronously loading images should not be tied directly to an UIImageView inside a table cell.  With the new fix, image fetching (and caching) has been moved to the WVFacebookFriend objects.  Upon initialization, the WVFacebookFriend uses AFNetworking extensions to load the image to a temporary UIImageView, caching the image in the AFNetworking image cache.  Requests to the WVFacebookFriend object for its picture will return either an image in the cache or a placeholder image while the object tries to fetch (and cache) the image.  If the WVFacebookFriend object needs to fetch the image, it notifies the view controller and the table view upon success that the relevant row should be reloaded if it is visible.

-----
Edited:  Monday, 19 May 2014
• Addressed enhancement issue #2:  Implement automatically updating version labels.
• Fixed bug issue #3:  Blocks with self should use weak refs (when retain cycles can occur).
• Fixed bug issue #4:  Invisibly re-request interrupted asynchronous image loads.
• Fixed bug issue #5:  AFNetworking and UIImageView async image loading race condition when scrolling quickly.

Note:  Issue #5 was addressed by increasing the size of the table cell prototype queue, from recommendations in AFNetworking forums.  If it doesn't completely fix the problem, then the pictures may have to be handled separately, not with the AFNetworking UIImageView convenience function.

-----
Edited:  Tuesday, 6 May 2014
• Fixed bug tracking issue #1 for nested init functions in WVFacebookFriend.m.
  Updated version/build to 1.01; manually updated visible labels.

-----
First commit:  Monday, 28 April 2014

---------------------------------------------

Challenge:
  
    ------------------------------
Create an iOS app (iOS7 +) that does the following:

• Authenticate with Facebook
• List all your Facebook friends names and profile pictures
• You should be able to filter the list with a search query
• The list should be sorted and displayed (first + last name order) the same way as the user’s address book
• The data (list of friends) doesn’t need to be persistent and should be refreshed when the user starts the app
• External libraries are acceptable except the Facebook SDK
• Use Cocoapods for external libraries dependencies
• Proper error handling
• Have a minimum of 2 view controllers (UIViewController subclasses, one for the authentication and a second for listing your friends)
    ------------------------------

At some point, the challenge added a requirement that the project must start with a Git (or Git-like) repository.  Unfortunately, the new requirement was not communicated until the raw code was already packaged for submission, so no edit history is available to review.  (Sorry…)


App notes:
• The app title and the color theme are both inspired by the company’s main office location outside the US.  To reduce testing and interface design complexity for the limited time budget, the app is only designed for the iPhone.

• The app includes Cocoapods and the AFNetworking library.  The AFNetworking library provides easier ways to verify network connectivity, to load data and images asynchronously, and to parse JSON responses.

• The app uses a UIWebView to deal with the initial Facebook log in flow, mostly due to the several layers of authentication, including an extra form to grant specific access rights to the app.  Attempts to follow links that lead outside the Facebook log in flow will force the user to choose whether to leave the app or to reject the link.  Links to the alternative language log in flows are allowed.  After a successful login, requests to the Facebook Graph API use chained AFNetworking request ops.
  - Side note:  The original version of the app started with nice text fields for user and password, and executed JavaScript to inject the field values into a hidden UIWebView, but it was replaced with the visible UIWebView because the user should really see the app access rights form.

• The data is refreshed when the user launches the app or brings it into the foreground.  For simplicity, the app segues to the log in view controller to update access tokens.  It also makes it more obvious that the friend data is being refreshed when the friends list is very short.

• The app adds a log out option in the friends list view controller that will delete Facebook cookies prior to a segue to the log in view controller, forcing a full log in flow.

• The app includes an alerts manager object to manage multiple alerts and to execute the correct code block for an alert after it is dismissed.  Many error alerts will re-call the same function that encountered the error after giving the user a chance to address the error.
  - Note:  (An enhancement idea popped up while on vacation…)  Due to multiple alert dialogs appearing for some errors, the alerts manager could be improved to ignore additional identical alert requests for alerts already being displayed (i.e., those alerts with tags being tracked in a dictionary until they are dismissed).  It could require creating error code IDs for each alert call location.

• For this challenge, the error handling is intended to be fairly visible to the user.  In a commercial app, requests with errors should be resubmitted more discreetly, alerting the user only for significant issues that cannot be addressed with request resubmissions or with cached data.

• Reduced sets of friend ID indices filtered by search filter substrings are cached to immediately return results for identical searches and to reduce the search space for substrings with a cached prefix.


