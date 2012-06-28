//
//  GRTMainViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTStopListViewController.h"
#import <MessageUI/MessageUI.h>

@interface GRTMainViewController : UITableViewController <MFMessageComposeViewControllerDelegate>

// outlets
@property (assign, nonatomic) IBOutlet UIBarButtonItem *sendTextButton;

// properties
@property (retain, nonatomic) NSNumber *busStopNumber;
@property (retain, nonatomic) NSString *busStopName;

// actions
- (IBAction)sendTextToGrtWhenClick:(UIBarButtonItem *)sender;
- (IBAction)toggleDisplay:(UISegmentedControl *)sender;

@end
