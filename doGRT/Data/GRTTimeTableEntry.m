//
//  GRTTimeTableEntry.m
//  doGRT
//
//  Created by Greg Wang on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTTimeTableEntry.h"

@implementation GRTTimeTableEntry

@synthesize routeId = _routeId;
/*routeLongName, routeShortName,*/ 
@synthesize tripHeadsign = _tripHeadsign;
@synthesize arrivalTime = _arrivalTime;
@synthesize departureTime = _departureTime;

- (GRTTimeTableEntry *) initWithRouteId:(NSString *)routeId 
						   tripHeadsign:(NSString *)tripHeadsign 
							arrivalTime:(NSNumber *)arrivalTime 
						  departureTime:(NSNumber *)departureTime{
	self = [super init];
	self.routeId = routeId;
	self.tripHeadsign = tripHeadsign;
	self.arrivalTime = arrivalTime;
	self.departureTime = departureTime;
	return self;
}

@end
