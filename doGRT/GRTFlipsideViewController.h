//
//  GRTFlipsideViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRTAddingViewController.h"

@class GRTFlipsideViewController;

@protocol GRTFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinishWithBusStopNumber:(NSNumber *)busStopNumber 
										 withBusStopName:(NSString *)busStopName;
@end

@interface GRTFlipsideViewController : UITableViewController <GRTAddingViewControllerDelegate>

@property (weak, nonatomic) IBOutlet id <GRTFlipsideViewControllerDelegate> delegate;
@property (assign, nonatomic) IBOutlet UITableViewCell *busStopCell;

@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (retain, nonatomic) NSMutableArray *busStopArray;

@end
