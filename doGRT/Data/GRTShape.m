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

@end

@implementation GRTShape

@synthesize shapeId = _shapeId;
@synthesize shapePts = _shapePts;

- (GRTShape *)initWithShapeId:(NSNumber *)shapeId shapePts:(NSArray *)shapePts
{
	self = [super init];
	if (self != nil) {
		self.shapeId = shapeId;
		self.shapePts = shapePts;
	}
	return self;
}

@end
