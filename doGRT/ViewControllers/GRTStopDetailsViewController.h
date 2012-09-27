//
//  GRTStopDetailsViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

@class GRTStopTimes;

@interface GRTStopDetailsViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) GRTStopTimes *stopTimes;

- (IBAction)toggleStopFavorite:(id)sender;

@end
