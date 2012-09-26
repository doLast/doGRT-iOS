//
//  GRTRoute.h
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

@interface GRTRoute : NSObject

@property (nonatomic, strong, readonly) NSNumber *routeId;
@property (nonatomic, strong, readonly) NSString *routeShortName;
@property (nonatomic, strong, readonly) NSString *routeLongName;
@property (nonatomic, strong, readonly) NSNumber *routeType;

- (GRTRoute *)initWithRouteId:(NSNumber *)routeId routeShortName:(NSString *)routeShortName routeLongName:(NSString *)routeLongName routeType:(NSNumber *)routeType;

@end
