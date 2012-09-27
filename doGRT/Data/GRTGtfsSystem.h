//
//  GRTGtfsSystem.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import <MapKit/MapKit.h>
#import "GRTStopTime.h"
#import "GRTStop.h"
#import "GRTTrip.h"
#import "GRTRoute.h"
#import "GRTShapePt.h"
#import "GRTService.h"
#import "GRTStopTimes.h"

@class GRTStop;
@class GRTStopTimes;

@interface GRTGtfsSystem : NSObject

+ (GRTGtfsSystem *)defaultGtfsSystem;

- (NSArray *)stopsInRegion:(MKCoordinateRegion)region;
- (NSArray *)stopsWithNameLike:(NSString *)str;

@end