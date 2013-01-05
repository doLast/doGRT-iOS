//
//  GRTStopDetailsViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

#import "GRTStopTimesViewController.h"
#import "GRTStopRoutesViewController.h"
#import "GRTStopDetailsManager.h"

@interface GRTStopDetailsViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, GRTStopTimesViewControllerDelegate, GRTStopRoutesViewControllerDelegate, GRTStopDetailsManagerDelegate>

@property (nonatomic, strong) GRTStopDetailsManager *stopDetailsManager;
@property (nonatomic, weak) IBOutlet UISegmentedControl *viewsSegmentedControl;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *favButton;
@property (nonatomic) NSArray *stopTimes;

- (IBAction)toggleViews:(id)sender;
- (IBAction)toggleStopFavorite:(id)sender;

@end
