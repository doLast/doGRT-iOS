//
//  GRTRouteEntry.m
//  doGRT
//
//  Created by Greg Wang on 12-2-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTTrip.h"

@interface GRTTrip ()

@property (nonatomic, strong) NSNumber *tripId;
@property (nonatomic, strong) NSString *tripHeadsign;
@property (nonatomic, strong) NSNumber *routeId;
@property (nonatomic, strong) NSNumber *shapeId;

@end

@implementation GRTTrip

@synthesize tripId = _tripId;
@synthesize tripHeadsign = _tripHeadsign;
@synthesize routeId = _routeId;
@synthesize shapeId = _shapeId;

- (GRTRoute *)route
{
	return nil; // TODO
}

- (GRTShape *)shape
{
	return nil; // TODO
}

- (GRTTrip *)initWithTripId:(NSNumber *)tripId tripHeadsign:(NSString *)tripHeadsign routeId:(NSNumber *)routeId shapeId:(NSNumber *)shapeId
{
	self = [super init];
	if (self != nil) {
		self.tripId = tripId;
		self.tripHeadsign = tripHeadsign;
		self.routeId = routeId;
		self.shapeId = shapeId;
	}
	return self;
}

@end
