//
//  GRTStopTimesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import <UIKit/UIKit.h>

@interface GRTStopTimesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
