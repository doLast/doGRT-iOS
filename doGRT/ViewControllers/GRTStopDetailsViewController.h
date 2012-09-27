//
//  GRTStopDetailsViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

#import "GRTStopTimesViewController.h"
#import "GRTStopRoutesViewController.h"

@class GRTStopTimes;

@interface GRTStopDetailsViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, GRTStopTimesViewControllerDelegate, GRTStopRoutesViewControllerDelegate>

@property (nonatomic, strong) GRTStopTimes *stopTimes;
@property (nonatomic, weak) IBOutlet UISegmentedControl *viewsSegmentedControl;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *favButton;

- (IBAction)toggleViews:(id)sender;
- (IBAction)toggleStopFavorite:(id)sender;

@end
