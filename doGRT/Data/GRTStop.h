//
//  GRTBusStopEntry.h
//  doGRT
//
//  Created by Greg Wang on 12-1-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class GRTStop;

@protocol GRTStopAnnotation <MKAnnotation>

@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, readonly) GRTStop *stop;

@end

@interface GRTStop : NSObject <GRTStopAnnotation>

@property (nonatomic, strong, readonly) NSNumber *stopId;
@property (nonatomic, strong, readonly) NSString *stopName;
@property (nonatomic, strong, readonly) CLLocation *location;

@property (nonatomic, readonly) GRTStop *stop;

// Center latitude and longitude of the annotion view.
// The implementation of this property must be KVO compliant.
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

// Title and subtitle for use by selection UI.
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *subtitle;

- (GRTStop *) initWithStopId:(NSNumber *)stopId stopName:(NSString *)stopName stopLat:(NSNumber *)stopLat stopLon:(NSNumber *)stopLon;

@end
