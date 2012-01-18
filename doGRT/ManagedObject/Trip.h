//
//  Trip.h
//  doGRT
//
//  Created by Greg Wang on 12-1-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Trip : NSManagedObject

@property (nonatomic, retain) NSString * tripId;
@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * tripHeadsign;
@property (nonatomic, retain) NSString * serviceId;

@end
