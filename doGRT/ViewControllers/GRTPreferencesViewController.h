//
//  GRTPreferencesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-10-24.
//
//

#import <QuickDialog/QuickDialog.h>
#import <MessageUI/MessageUI.h>

@interface GRTPreferencesViewController : QuickDialogController <MFMailComposeViewControllerDelegate>

+ (void)showPreferencesInViewController:(UIViewController *)viewController;
+ (void)showPreferencesFromBarButtonItem:(UIBarButtonItem *)barButtonItem;

@end
