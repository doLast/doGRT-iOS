//
//  GRTMainViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTFlipsideViewController.h"
#import <MessageUI/MessageUI.h>

#import <CoreData/CoreData.h>

@interface GRTMainViewController : UITableViewController <GRTFlipsideViewControllerDelegate,  MFMessageComposeViewControllerDelegate>

//@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (assign, nonatomic) IBOutlet UIBarButtonItem *sendTextButton;
@property (retain, nonatomic) NSNumber *busStopNumber;
@property (retain, nonatomic) NSNumber *lastBusStopNumber;
@property (retain, nonatomic) NSString *busStopName;
//@property (retain, nonatomic) NSIndexPath *lastLeft;
@property (assign, nonatomic) NSInteger curTime;

@property (assign, nonatomic) IBOutlet UITableViewCell *timeTableCell;
@property (retain, nonatomic) NSMutableArray *timeTableArray;

- (IBAction)sendTextToGrtWhenClick:(UIBarButtonItem *)sender;

@end
