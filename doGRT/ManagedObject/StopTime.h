//
//  StopTime.h
//  doGRT
//
//  Created by Greg Wang on 12-1-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface StopTime : NSManagedObject

@property (nonatomic, retain) NSString * tripId;
@property (nonatomic, retain) NSNumber * arrivalTime;
@property (nonatomic, retain) NSNumber * departureTime;
@property (nonatomic, retain) NSNumber * stopId;
@property (nonatomic, retain) NSNumber * stopSequence;

@end
