//
//  GRTMainViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTFlipsideViewController.h"
#import <MessageUI/MessageUI.h>

@interface GRTMainViewController : UITableViewController <MFMessageComposeViewControllerDelegate>

// outlets
@property (assign, nonatomic) IBOutlet UIBarButtonItem *sendTextButton;
@property (assign, nonatomic) IBOutlet UITableViewCell *timeTableCell;

// properties
@property (retain, nonatomic) NSNumber *busStopNumber;
@property (retain, nonatomic) NSString *busStopName;

// actions
- (IBAction)sendTextToGrtWhenClick:(UIBarButtonItem *)sender;

@end
