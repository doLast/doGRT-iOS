//
//  GRTFlipsideViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRTAddingViewController.h"

@interface GRTStopListViewController : UITableViewController <GRTAddingViewControllerDelegate, UIAlertViewDelegate>

@property (assign, nonatomic) IBOutlet UITableViewCell *busStopCell;
@property (assign, nonatomic) IBOutlet UILabel *helpMessage;

@end
