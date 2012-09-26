//
//  GRTRouteEntry.m
//  doGRT
//
//  Created by Greg Wang on 12-2-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTTrip.h"
#import "GRTGtfsSystem+Internal.h"

@interface GRTTrip ()

@property (nonatomic, strong) NSNumber *tripId;
@property (nonatomic, strong) NSString *tripHeadsign;
@property (nonatomic, strong) NSNumber *routeId;
@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic, strong) NSNumber *shapeId;

@end

@implementation GRTTrip

@synthesize tripId = _tripId;
@synthesize tripHeadsign = _tripHeadsign;
@synthesize routeId = _routeId;
@synthesize serviceId = _serviceId;
@synthesize shapeId = _shapeId;

- (GRTRoute *)route
{
	return [[GRTGtfsSystem defaultGtfsSystem] routeById:self.routeId];
}

- (GRTService *)service
{
	return [[GRTGtfsSystem defaultGtfsSystem] serviceById:self.serviceId];
}

- (GRTShape *)shape
{
	return [[GRTGtfsSystem defaultGtfsSystem] shapeById:self.shapeId];
}

- (GRTTrip *)initWithTripId:(NSNumber *)tripId tripHeadsign:(NSString *)tripHeadsign routeId:(NSNumber *)routeId serviceId:(NSString *)serviceId shapeId:(NSNumber *)shapeId
{
	self = [super init];
	if (self != nil) {
		self.tripId = tripId;
		self.tripHeadsign = tripHeadsign;
		self.routeId = routeId;
		self.serviceId = serviceId;
		self.shapeId = shapeId;
	}
	return self;
}

@end
