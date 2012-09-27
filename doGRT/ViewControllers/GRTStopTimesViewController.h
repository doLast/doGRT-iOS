//
//  GRTStopTimesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

@class GRTStopTimes;

@interface GRTStopTimesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GRTStopTimes *stopTimes;

- (IBAction)toggleStopFavorite:(id)sender;

@end
