//
//  GRTShape.h
//  doGRT
//
//  Created by Greg Wang on 12-9-29.
//
//

#import "GRTShapePt.h"
#import <MapKit/MapKit.h>

@interface GRTShape : NSObject

@property (nonatomic, strong, readonly) NSNumber *shapeId;
@property (nonatomic, strong, readonly) NSArray *shapePts;
@property (nonatomic, strong, readonly) MKPolyline *polyline;

- (GRTShape *)initWithShapeId:(NSNumber *)shapeId shapePts:(NSArray *)shapePts;

@end
