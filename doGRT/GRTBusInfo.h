//
//  GRTBusInfo.h
//  doGRT
//
//  Created by Greg Wang on 12-1-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "FMDatabase.h"


@interface GRTBusInfo : NSObject

+ (FMDatabase *) openDB;
+ (NSArray *) getBusStopsAt:(CLLocationCoordinate2D)coordinate 
					 inSpan:(MKCoordinateSpan)span 
				  withLimit:(NSUInteger)limit;
+ (NSString *) getBusStopNameById:(NSNumber *)stopId;
+ (NSArray *) getCurrentTimeTableById:(NSNumber *)stopId;
+ (NSArray *) getTimeTableById:(NSNumber *)stopId forDate:(NSDate *)date;
+ (NSArray *) getTimeTableById:(NSNumber *)stopId 
						forDay:(NSString *)day 
					   andDate:(NSUInteger)date
					 withLimit:(NSUInteger)limit;

@end
