//
//  GRTStopRoutesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-2-10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GRTStopRoutesViewController : UIViewController <UITableViewDelegate>

// outlets
@property (assign, nonatomic) IBOutlet UITableView *tableView;
@property (assign, nonatomic) IBOutlet UITableViewCell *tableCell;
@property (assign, nonatomic) IBOutlet UINavigationItem *navigationBar;

// properties
@property (retain, nonatomic) NSNumber *busStopNumber;

- (IBAction) backToAddingWhenClick:(UIBarButtonItem *)sender;

@end
