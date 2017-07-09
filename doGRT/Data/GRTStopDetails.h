//
//  GRTStopDetails.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTStopTime.h"

@class GRTStop;
@class GRTRoute;

@interface GRTStopDetails : NSObject

@property (nonatomic, strong, readonly) GRTStop *stop;

- (NSArray *)stopTimesForDate:(NSDate *)date;
- (NSArray *)stopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route;
- (NSArray *)routes;

- (GRTStopDetails *)initWithStop:(GRTStop *)stop;

@end
