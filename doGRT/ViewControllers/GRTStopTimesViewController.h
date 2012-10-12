//
//  GRTStopTimesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

@class GRTStopTime;
@class GRTStopTimesViewController;

@protocol GRTStopTimesViewControllerDelegate <NSObject>

- (void)stopTimesViewController:(GRTStopTimesViewController *)stopTimesViewController didSelectStopTime:(GRTStopTime *)stopTime;

@end

@interface GRTStopTimesViewController : UITableViewController

@property (nonatomic, weak) id<GRTStopTimesViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *stopTimes;

- (void)showTripDetailsForStopTime:(GRTStopTime *)stopTime inNavigationController:(UINavigationController *)navigationController;

@end
