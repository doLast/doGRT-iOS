//
//  GRTStopTimes.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

@class GRTStop;
@class GRTRoute;

@interface GRTStopTimes : NSObject

@property (nonatomic, copy, readonly) GRTStop *stop;

- (NSArray *)stopTimesForDate:(NSDate *)date;
- (NSArray *)stopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route;
- (NSArray *)routesForDate:(NSDate *)date;

- (GRTStopTimes *)initWithStop:(GRTStop *)stop;

@end
