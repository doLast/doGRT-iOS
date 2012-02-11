//
//  GRTBusStopEntry.h
//  doGRT
//
//  Created by Greg Wang on 12-1-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface GRTBusStopEntry : NSObject <MKAnnotation>

@property (retain, nonatomic) NSNumber *stopId;
@property (retain, nonatomic) NSString *stopName;
@property (nonatomic, readonly) NSNumber *stopLat;
@property (nonatomic, readonly) NSNumber *stopLon;

// Center latitude and longitude of the annotion view.
// The implementation of this property must be KVO compliant.
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

// Title and subtitle for use by selection UI.
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

- (GRTBusStopEntry *) initAtCoordinate:(CLLocationCoordinate2D)coordinate
							withStopId:(NSNumber *)stopId 
						  withStopName:(NSString *)stopName;

@end
