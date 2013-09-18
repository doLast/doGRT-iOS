//
//  GRTTimeTableEntry.h
//  doGRT
//
//  Created by Greg Wang on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

@class GRTTrip;
@class GRTStop;

#import "GRTStop.h"

@interface GRTStopTime : NSObject <GRTStopAnnotation>

@property (nonatomic, weak, readonly) GRTTrip *trip;
@property (nonatomic, strong, readonly) NSNumber *stopSequence;
@property (nonatomic, weak, readonly) GRTStop *stop;
@property (nonatomic, strong, readonly) NSNumber *arrivalTime;
@property (nonatomic, strong, readonly) NSNumber *departureTime;

@property (nonatomic, readonly) CLLocation *location;

// Center latitude and longitude of the annotion view.
// The implementation of this property must be KVO compliant.
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

// Title and subtitle for use by selection UI.
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

- (GRTStopTime *)initWithTripId:(NSNumber *)tripId stopSequence:(NSNumber *)stopSequence stopId:(NSNumber *)stopId arrivalTime:(NSNumber *)arrivalTime departureTime:(NSNumber *)departureTime;

@end
