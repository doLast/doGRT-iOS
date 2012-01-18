//
//  BusStop.h
//  doGRT
//
//  Created by Greg Wang on 12-1-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BusStop : NSManagedObject

@property (nonatomic, retain) NSNumber * stopId;
@property (nonatomic, retain) NSString * stopName;
@property (nonatomic, retain) NSNumber * stopLat;
@property (nonatomic, retain) NSNumber * stopLon;

@end
