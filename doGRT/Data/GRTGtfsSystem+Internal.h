//
//  GRTGtfsSystem+Internal.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTGtfsSystem.h"

@class FMDatabase;

@interface GRTGtfsSystem (Internal)
@property (nonatomic, strong, readonly) FMDatabase *db;
@property (nonatomic, strong, readonly) NSCache *services;
@property (nonatomic, strong, readonly) NSDictionary *stops;
@property (nonatomic, strong, readonly) NSCache *routes;
@property (nonatomic, strong, readonly) NSCache *trips;
@property (nonatomic, strong, readonly) NSCache *shapes;

- (GRTService *)serviceById:(NSString *)serviceId;
- (GRTStop *)stopById:(NSNumber *)stopId;
- (GRTRoute *)routeById:(NSNumber *)routeId;
- (GRTTrip *)tripById:(NSNumber *)tripId;
- (GRTShape *)shapeById:(NSNumber *)shapeId;

@end
