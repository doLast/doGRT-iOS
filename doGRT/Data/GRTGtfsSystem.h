//
//  GRTGtfsSystem.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import <MapKit/MapKit.h>
#import "GRTStop.h"
#import "GRTTrip.h"
#import "GRTRoute.h"
#import "GRTShape.h"
#import "GRTService.h"
#import "GRTStopTimes.h"

@class GRTStop;
@class GRTStopTimes;

extern NSString * const kGRTGtfsDataVersionKey;

@interface GRTGtfsSystem : NSObject

+ (GRTGtfsSystem *)defaultGtfsSystem;

- (void)bootstrap;

- (NSArray *)stopsInRegion:(MKCoordinateRegion)region;
- (NSArray *)stopsAroundLocation:(CLLocation *)location withinDistance:(CLLocationDistance)distance;
- (NSArray *)stopsWithNameLike:(NSString *)str;
- (NSArray *)stopTimesForTrip:(GRTTrip *)trip;

@end
