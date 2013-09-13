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

@interface GRTStopDetailsViewController : UIViewController <GRTStopTimesViewControllerDelegate, GRTStopRoutesViewControllerDelegate, GRTStopDetailsManagerDelegate>

@property (nonatomic, strong) GRTStopDetailsManager *stopDetailsManager;
@property (nonatomic, weak) IBOutlet UISegmentedControl *viewsSegmentedControl;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *favButton;
@property (nonatomic, weak) IBOutlet GRTStopTimesViewController *stopTimesViewController;
@property (nonatomic, weak) IBOutlet GRTStopRoutesViewController *stopRoutesViewController;

- (IBAction)toggleViews:(UISegmentedControl *)sender;
- (IBAction)toggleStopFavorite:(id)sender;

@end
