//
//  GRTStopDetailsViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

#import "GRTStopTimesViewController.h"
#import "GRTStopRoutesViewController.h"
#import "PopoverView.h"

@class GRTStopDetails;

@interface GRTStopDetailsViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, GRTStopTimesViewControllerDelegate, GRTStopRoutesViewControllerDelegate, PopoverViewDelegate>

@property (nonatomic, strong) GRTStopDetails *stopDetails;
@property (nonatomic, weak) IBOutlet UISegmentedControl *viewsSegmentedControl;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *favButton;

- (IBAction)toggleViews:(id)sender;
- (IBAction)toggleStopFavorite:(id)sender;

@end
