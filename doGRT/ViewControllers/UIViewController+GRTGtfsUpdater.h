//
//  UIViewController+GRTGtfsUpdater.h
//  doGRT
//
//  Created by Greg Wang on 12-10-14.
//
//

@class ITProgressBarItemSet;

@interface UIViewController (GRTGtfsUpdater)

@property (nonatomic, strong, readonly) ITProgressBarItemSet *updateProgressBarItemSet;

- (void)becomeGtfsUpdater;
- (void)quitGtfsUpdater;
- (void)updateGtfsUpdaterStatus;
- (IBAction)checkForUpdate:(id)sender;

@end
