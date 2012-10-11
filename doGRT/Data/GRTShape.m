//
//  GRTShape.m
//  doGRT
//
//  Created by Greg Wang on 12-9-29.
//
//

#import "GRTShape.h"

@interface GRTShape ()

@property (nonatomic, strong) NSNumber *shapeId;
@property (nonatomic, strong) NSArray *shapePts;
@property (nonatomic, strong) MKPolyline *polyline;

@end

@implementation GRTShape

@synthesize shapeId = _shapeId;
@synthesize shapePts = _shapePts;
@synthesize polyline = _polyline;

- (GRTShape *)initWithShapeId:(NSNumber *)shapeId shapePts:(NSArray *)shapePts
{
	self = [super init];
	if (self != nil) {
		self.shapeId = shapeId;
		self.shapePts = shapePts;
		
		int i = 0;
		CLLocationCoordinate2D coordinates[[shapePts count]];
		for (GRTShapePt *shapePt in shapePts) {
			coordinates[i] = shapePt.coordinate;
			i++;
		}
		self.polyline = [MKPolyline polylineWithCoordinates:coordinates count:[shapePts count]];
	}
	return self;
}

@end
