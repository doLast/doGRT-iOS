//
//  GRTShapePt.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTShapePt.h"

@interface GRTShapePt ()

@property (nonatomic) CLLocationCoordinate2D coordinate;

@end

@implementation GRTShapePt

@synthesize coordinate = _coordinate;

- (NSNumber *)ptLat
{
	return [NSNumber numberWithDouble:self.coordinate.latitude];
}

- (NSNumber *)ptLon
{
	return [NSNumber numberWithDouble:self.coordinate.longitude];
}

- (GRTShapePt *)initWithLat:(NSNumber *)lat lon:(NSNumber *)lon
{
	self = [super init];
	if (self != nil) {
		self.coordinate = CLLocationCoordinate2DMake([lat doubleValue], [lon doubleValue]);
	}
	return self;
}

@end
