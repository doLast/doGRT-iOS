//
//  GRTPreferencesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-10-24.
//
//

#import <QuickDialog/QuickDialog.h>

@interface GRTPreferencesViewController : QuickDialogController <QuickDialogStyleProvider>

+ (void)showPreferencesInViewController:(UIViewController *)viewController;
+ (void)showPreferencesFromBarButtonItem:(UIBarButtonItem *)barButtonItem;

@end
