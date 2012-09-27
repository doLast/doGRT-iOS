//
//  GRTStopTimesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

@class GRTStopTime;

@protocol GRTStopTimesViewControllerDelegate <NSObject>

- (void)didSelectStopTime:(GRTStopTime *)stopTime;

@end

@interface GRTStopTimesViewController : UITableViewController

@property (nonatomic, weak) id<GRTStopTimesViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *stopTimes;

@end
