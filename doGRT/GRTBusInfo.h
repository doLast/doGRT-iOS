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

/* Class Methods */
+ (FMDatabase *) openDB;
+ (NSArray *) getBusStopsAt:(CLLocationCoordinate2D)coordinate 
					 inSpan:(MKCoordinateSpan)span 
				  withLimit:(NSUInteger)limit;
+ (NSArray *) getBusStopsByRouteId:(NSString *)routeId;
+ (NSString *) getBusStopNameByStop:(NSNumber *)stopId;

+ (NSArray *) getTripsByStop:(NSNumber *)stopId;
+ (NSArray *) getRoutesByStop:(NSNumber *)stopId;

/* Instance Methods */
- (GRTBusInfo *)initByStop:(NSNumber *)stopId;

//- (NSArray *) getCurrentRoutes;
- (NSArray *) getCurrentTimeTable;
- (NSArray *) getCurrentTimeTableByRoute:(NSString *)routeId;

//- (NSArray *) getTimeTableById:(NSNumber *)stopId 
//					   forDate:(NSDate *)date;
//- (NSArray *) getTimeTableById:(NSNumber *)stopId 
//					   byRoute:(NSNumber *)routeId
//					   forDate:(NSDate *)date;


@end
