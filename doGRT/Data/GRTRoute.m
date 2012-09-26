//
//  GRTRoute.m
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import "GRTRoute.h"

@interface GRTRoute ()

@property (nonatomic, strong) NSNumber *routeId;
@property (nonatomic, strong) NSString *routeShortName;
@property (nonatomic, strong) NSString *routeLongName;
@property (nonatomic, strong) NSNumber *routeType;

@end

@implementation GRTRoute

@synthesize routeId = _routeId;
@synthesize routeShortName = _routeShortName;
@synthesize routeLongName = _routeLongName;
@synthesize routeType = _routeType;

- (GRTRoute *)initWithRouteId:(NSNumber *)routeId routeShortName:(NSString *)routeShortName routeLongName:(NSString *)routeLongName routeType:(NSNumber *)routeType
{
	self = [super init];
	if (self != nil) {
		self.routeId = routeId;
		self.routeShortName = routeShortName;
		self.routeLongName = routeLongName;
		self.routeType = routeType;
	}
	return self;
}

@end
