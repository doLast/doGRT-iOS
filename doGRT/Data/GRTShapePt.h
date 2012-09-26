//
//  GRTShapePt.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import <CoreLocation/CoreLocation.h>

@interface GRTShapePt : NSObject

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSNumber *ptLat;
@property (nonatomic, readonly) NSNumber *ptLon;

- (GRTShapePt *)initWithLat:(NSNumber *)lat lon:(NSNumber *)lon;

@end
