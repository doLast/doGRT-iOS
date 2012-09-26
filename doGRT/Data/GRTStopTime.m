//
//  GRTTimeTableEntry.m
//  doGRT
//
//  Created by Greg Wang on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTStopTime.h"
#import "GRTGtfsSystem+Internal.h"

@interface GRTStopTime ()

@property (nonatomic, strong) NSNumber *tripId;
@property (nonatomic, strong) NSNumber *arrivalTime;
@property (nonatomic, strong) NSNumber *departureTime;

@end

@implementation GRTStopTime

@synthesize tripId = _tripId;
@synthesize arrivalTime = _arrivalTime;
@synthesize departureTime = _departureTime;

- (GRTTrip *)trip
{
	return [[GRTGtfsSystem defaultGtfsSystem] tripById:self.tripId];
}

- (GRTStopTime *)initWithTripId:(NSNumber *)tripId arrivalTime:(NSNumber *)arrivalTime departureTime:(NSNumber *)departureTime
{
	self = [super init];
	if (self != nil) {
		self.tripId = tripId;
		self.arrivalTime = arrivalTime;
		self.departureTime = departureTime;
	}
	return self;
}

@end
