//
//  GRTRouteEntry.h
//  doGRT
//
//  Created by Greg Wang on 12-2-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

@class GRTRoute;
@class GRTService;
@class GRTShape;

@interface GRTTrip : NSObject

@property (nonatomic, strong, readonly) NSNumber *tripId;
@property (nonatomic, strong, readonly) NSString *tripHeadsign;
@property (nonatomic, weak, readonly) GRTRoute *route;
@property (nonatomic, weak, readonly) GRTService *service;
@property (nonatomic, weak, readonly) GRTShape *shape;
@property (nonatomic, strong, readonly) NSArray *stopTimes;
@property (nonatomic, readonly) NSUInteger totalStops;

- (GRTTrip *)initWithTripId:(NSNumber *)tripId tripHeadsign:(NSString *)tripHeadsign routeId:(NSNumber *)routeId serviceId:(NSString *)serviceId shapeId:(NSNumber *)shapeId;

@end
