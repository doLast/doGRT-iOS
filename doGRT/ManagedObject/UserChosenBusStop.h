//
//  UserChosenBusStop.h
//  doGRT
//
//  Created by Greg Wang on 12-1-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UserChosenBusStop : NSManagedObject

@property (nonatomic, retain) NSNumber * stopId;
@property (nonatomic, retain) NSDate * addTime;
@property (nonatomic, retain) NSString * stopName;

@end
