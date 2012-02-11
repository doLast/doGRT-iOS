//
//  GRTRouteTimeViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-2-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GRTTripEntry;
@class GRTBusInfo;

@interface GRTRouteTimeViewController : UITableViewController

// outlets
@property (assign, nonatomic) IBOutlet UITableViewCell *tableCell;

// properties
@property (retain, nonatomic) GRTBusInfo *busInfo;
@property (retain, nonatomic) GRTTripEntry *route;

@end
