//
//  GRTStopTimesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTStopDetailsManager.h"

@class GRTStopTime;
@class GRTStopTimesViewController;
@class GRTStopsMapViewController;

@protocol GRTStopTimesViewControllerDelegate <NSObject>

- (void)stopTimesViewController:(GRTStopTimesViewController *)stopTimesViewController didSelectStopTime:(GRTStopTime *)stopTime;

@end

@interface GRTStopTimesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, GRTStopDetailsManagerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GRTStopDetailsManager *stopDetailsManager;
@property (nonatomic, weak) IBOutlet id<GRTStopTimesViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *stopTimes;
@property (nonatomic, readonly) BOOL splitLeftAndComingBuses;

- (void)pushTripDetailsForStopTime:(GRTStopTime *)stopTime
			toNavigationController:(UINavigationController *)navigationController;
- (void)pushTripDetailsView:(GRTStopsMapViewController *)tripDetailsVC
				forStopTime:(GRTStopTime *)stopTime
	 toNavigationController:(UINavigationController *)navigationController;
- (void)setStopTimes:(NSArray *)stopTimes splitLeftAndComingBuses:(BOOL)split;
- (void)scrollToAppropriateIndexAnimated:(BOOL)animated;

@end
