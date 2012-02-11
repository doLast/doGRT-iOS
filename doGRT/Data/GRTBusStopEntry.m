//
//  GRTBusStopEntry.m
//  doGRT
//
//  Created by Greg Wang on 12-1-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTBusStopEntry.h"

@implementation GRTBusStopEntry

@synthesize stopId = _stopId;
@synthesize stopName = _stopName;
@synthesize coordinate = _coordinate;

- (NSString *) title {
	return _stopName;
}

- (NSString *) subtitle {
	return [NSString stringWithFormat:@"%@", _stopId];
}

- (NSNumber *) stopLat {
	return [NSNumber numberWithDouble:_coordinate.latitude];
}

- (NSNumber *) stopLon {
	return [NSNumber numberWithDouble:_coordinate.longitude];
}

- (GRTBusStopEntry *) initAtCoordinate:(CLLocationCoordinate2D)coordinate
							withStopId:(NSNumber *)stopId 
						  withStopName:(NSString *)stopName{
	self = [super init];
	if(self != nil){
		_coordinate = coordinate;
		_stopId = stopId;
		_stopName = stopName;
	}
	return self;
}

@end
