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

@interface GRTStopDetailsViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, GRTStopRoutesViewControllerDelegate>

@property (nonatomic, strong) GRTStopTimes *stopTimes;

- (IBAction)toggleStopFavorite:(id)sender;

@end
