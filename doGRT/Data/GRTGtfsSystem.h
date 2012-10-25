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

extern NSString * const GRTGtfsDataVersionKey;
extern NSString * const GRTGtfsDataUpdateAvailableNotification;
extern NSString * const GRTGtfsDataUpdateInProgressNotification;
extern NSString * const GRTGtfsDataUpdateDidFinishNotification;

@class GRTStop;
@class GRTStopTimes;
@class GRTGtfsSystem;

@interface GRTGtfsSystem : NSObject

+ (GRTGtfsSystem *)defaultGtfsSystem;

#pragma mark - data preparation and update
- (void)bootstrap;
- (void)checkForUpdate;
- (void)startUpdate;
- (void)abortUpdate;

#pragma mark - data access
- (NSArray *)stopsInRegion:(MKCoordinateRegion)region;
- (NSArray *)stopsAroundLocation:(CLLocation *)location withinDistance:(CLLocationDistance)distance;
- (NSArray *)stopsWithNameLike:(NSString *)str;
- (NSArray *)stopTimesForTrip:(GRTTrip *)trip;

@end
