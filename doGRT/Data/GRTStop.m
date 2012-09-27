//
//  GRTBusStopEntry.m
//  doGRT
//
//  Created by Greg Wang on 12-1-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTStop.h"

@interface GRTStop ()

@property (nonatomic, strong) NSNumber *stopId;
@property (nonatomic, strong) NSString *stopName;
@property (nonatomic, strong) CLLocation *location;

@end

@implementation GRTStop

@synthesize stopId = _stopId;
@synthesize stopName = _stopName;
@synthesize location = _location;

- (GRTStop *)stop
{
	return self;
}

- (CLLocationCoordinate2D)coordinate
{
	return self.location.coordinate;
}

- (NSString *) title {
	return self.stopName;
}

- (NSString *) subtitle {
	return [NSString stringWithFormat:@"%@", self.stopId];
}

- (NSNumber *) stopLat {
	return [NSNumber numberWithDouble:self.coordinate.latitude];
}

- (NSNumber *) stopLon {
	return [NSNumber numberWithDouble:self.coordinate.longitude];
}

- (GRTStop *) initWithStopId:(NSNumber *)stopId stopName:(NSString *)stopName stopLat:(NSNumber *)stopLat stopLon:(NSNumber *)stopLon{
	self = [super init];
	if(self != nil){
		self.location = [[CLLocation alloc] initWithLatitude:[stopLat doubleValue] longitude:[stopLon doubleValue]];
		self.stopId = stopId;
		self.stopName = stopName;
	}
	return self;
}

@end
