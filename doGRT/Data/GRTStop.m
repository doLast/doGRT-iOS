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
@property (nonatomic) CLLocationCoordinate2D coordinate;

@end

@implementation GRTStop

@synthesize stopId = _stopId;
@synthesize stopName = _stopName;
@synthesize coordinate = _coordinate;

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
		self.coordinate = CLLocationCoordinate2DMake([stopLat doubleValue], [stopLon doubleValue]);
		self.stopId = stopId;
		self.stopName = stopName;
	}
	return self;
}

@end
