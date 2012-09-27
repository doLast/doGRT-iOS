//
//  GRTGtfsSystem+Internal.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTGtfsSystem+Internal.h"

#import "FMDatabase.h"

@implementation GRTGtfsSystem (Internal)

@dynamic db;
@dynamic services;
@dynamic stops;
@dynamic routes;
@dynamic trips;
@dynamic shapes;

- (GRTService *)serviceById:(NSString *)serviceId
{
	GRTService *service = [self.services objectForKey:serviceId];
	if (service == nil) {
		FMResultSet *result = [self.db executeQueryWithFormat:@"SELECT * \
							   FROM Calendar \
							   WHERE serviceId=%@", serviceId];
		if (result == nil){
			NSLog(@"%@", [self.db lastErrorMessage]);
			abort();
		}
		
		if ([result next]) {
			NSString *serviceId = [result stringForColumn:@"serviceId"];
			NSNumber *startDate = [NSNumber numberWithInt:[result intForColumn:@"startDate"]];
			NSNumber *endDate = [NSNumber numberWithInt:[result intForColumn:@"endDate"]];
			NSMutableSet *serviceDays = [NSMutableSet set];
			if ([result boolForColumn:@"sunday"]) [serviceDays addObject:@"sunday"];
			if ([result boolForColumn:@"monday"]) [serviceDays addObject:@"monday"];
			if ([result boolForColumn:@"tuesday"]) [serviceDays addObject:@"tuesday"];
			if ([result boolForColumn:@"wednesday"]) [serviceDays addObject:@"wednesday"];
			if ([result boolForColumn:@"thursday"]) [serviceDays addObject:@"thursday"];
			if ([result boolForColumn:@"friday"]) [serviceDays addObject:@"friday"];
			if ([result boolForColumn:@"saturday"]) [serviceDays addObject:@"saturday"];
			
			service = [[GRTService alloc] initWithServiceId:serviceId startDate:startDate endDate:endDate serviceDays:serviceDays];
			[self.services setObject:service forKey:service.serviceId];
		}
		
		[result close];
	}
	return service;
}

- (GRTStop *)stopById:(NSNumber *)stopId
{
	return [self.stops objectForKey:stopId];
}

- (GRTRoute *)routeById:(NSNumber *)routeId
{
	GRTRoute *route = [self.routes objectForKey:routeId];
	if (route == nil) {
		FMResultSet *result = [self.db executeQueryWithFormat:@"SELECT * \
							   FROM Route \
							   WHERE routeId=%@", routeId];
		if (result == nil){
			NSLog(@"%@", [self.db lastErrorMessage]);
			abort();
		}
		
		if ([result next]) {
			NSNumber *routeId = [NSNumber numberWithInt:[result intForColumn:@"routeId"]];
			NSString *routeLongName = [result stringForColumn:@"routeLongName"];
			NSString *routeShortName = [result stringForColumn:@"routeShortName"];
			
			route = [[GRTRoute alloc] initWithRouteId:routeId routeShortName:routeShortName routeLongName:routeLongName routeType:[NSNumber numberWithInt:3]];
			[self.routes setObject:route forKey:route.routeId];
		}
		
		[result close];
	}
	return route;
}

- (GRTTrip *)tripById:(NSNumber *)tripId
{
	GRTTrip *trip = [self.trips objectForKey:tripId];
	if (trip == nil) {
		FMResultSet *result = [self.db executeQueryWithFormat:@"SELECT * \
							   FROM Trip \
							   WHERE tripId=%@", tripId];
		if (result == nil){
			NSLog(@"%@", [self.db lastErrorMessage]);
			abort();
		}
		
		if ([result next]) {
			NSNumber *tripId = [NSNumber numberWithInt:[result intForColumn:@"tripId"]];
			NSString *tripHeadsign = [result stringForColumn:@"tripHeadsign"];
			NSNumber *routeId = [NSNumber numberWithInt:[result intForColumn:@"routeId"]];
			NSString *serviceId = [result stringForColumn:@"serviceId"];
			NSNumber *shapeId = nil;
//			NSNumber *shapeId = [NSNumber numberWithInt:[result intForColumn:@"shapeId"]];
			
			trip = [[GRTTrip alloc] initWithTripId:tripId tripHeadsign:tripHeadsign routeId:routeId serviceId:serviceId shapeId:shapeId];
			[self.trips	setObject:trip forKey:trip.tripId];
		}
		
		[result close];
	}
	return trip;
}

- (GRTShape *)shapeById:(NSNumber *)shapeId
{
	GRTShape *shape = [self.shapes objectForKey:shapeId];
	if (shape == nil) {
		// FETCH
	}
	return shape;
}

@end
