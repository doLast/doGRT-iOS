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
							   FROM calendar \
							   WHERE service_id=%@", serviceId];
		if (result == nil){
			NSLog(@"%@", [self.db lastErrorMessage]);
			abort();
		}
		
		if ([result next]) {
			NSString *serviceId = [result stringForColumn:@"service_id"];
			NSNumber *startDate = [NSNumber numberWithInt:[result intForColumn:@"start_date"]];
			NSNumber *endDate = [NSNumber numberWithInt:[result intForColumn:@"end_date"]];
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
							   FROM routes \
							   WHERE route_id=%@", routeId];
		if (result == nil){
			NSLog(@"%@", [self.db lastErrorMessage]);
			abort();
		}
		
		if ([result next]) {
			NSNumber *routeId = [NSNumber numberWithInt:[result intForColumn:@"route_id"]];
			NSString *routeLongName = [result stringForColumn:@"route_long_name"];
			NSString *routeShortName = [result stringForColumn:@"route_short_name"];
			
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
							   FROM trips \
							   WHERE trip_id=%@", tripId];
		if (result == nil){
			NSLog(@"%@", [self.db lastErrorMessage]);
			abort();
		}
		
		if ([result next]) {
			NSNumber *tripId = [NSNumber numberWithInt:[result intForColumn:@"trip_id"]];
			NSString *tripHeadsign = [result stringForColumn:@"trip_headsign"];
			NSNumber *routeId = [NSNumber numberWithInt:[result intForColumn:@"route_id"]];
			NSString *serviceId = [result stringForColumn:@"service_id"];
			NSNumber *shapeId = [NSNumber numberWithInt:[result intForColumn:@"shape_id"]];
			
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
		FMResultSet *result = [self.db executeQueryWithFormat:@"SELECT * \
							   FROM shapes \
							   WHERE shape_id=%@ \
							   ORDER BY shape_pt_sequence", shapeId];
		if (result == nil){
			NSLog(@"%@", [self.db lastErrorMessage]);
			abort();
		}
		
		NSMutableArray *shapePts = [NSMutableArray array];
		while ([result next]) {
			NSNumber *shapePtLat = [NSNumber numberWithDouble:[result doubleForColumn:@"shape_pt_lat"]];
			NSNumber *shapePtLon = [NSNumber numberWithDouble:[result doubleForColumn:@"shape_pt_lon"]];
//			NSNumber *shapeDistTraveled = [NSNumber numberWithDouble:[result doubleForColumn:@"shape_dist_traveled"]];
			
			GRTShapePt *shapePt = [[GRTShapePt alloc] initWithLat:shapePtLat lon:shapePtLon];
			[shapePts addObject:shapePt];
		}
		[result close];
		
		shape = [[GRTShape alloc] initWithShapeId:shapeId shapePts:shapePts];
		[self.shapes setObject:shape forKey:shapeId];
	}
	return shape;
}

- (NSArray *)stopTimesForTrip:(GRTTrip *)trip
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:trip.tripId];
	NSString *query = [NSString stringWithFormat:@"SELECT S.* \
					   FROM stop_times as S \
					   WHERE S.trip_id=? "];
	
	// execute database query
	FMDatabase *db = self.db;
	FMResultSet *result = [db executeQuery:query withArgumentsInArray:arguments];
	if (result == nil){
		NSLog(@"%@", [db lastErrorMessage]);
		abort();
	}
	
	// process the data
	NSMutableArray *stopTimes = [[NSMutableArray alloc] init];
	while ([result next]) {
		//retrieve values for each record
		NSNumber *tripId = [NSNumber numberWithInt:[result intForColumn:@"trip_id"]];
		NSNumber *stopSequence = [NSNumber numberWithInt:[result intForColumn:@"stop_sequence"]];
		NSNumber *stopId = [NSNumber numberWithInt:[result intForColumn:@"stop_id"]];
		NSInteger arrivalInt = [result intForColumn:@"arrival_time"];
		NSInteger departureInt = [result intForColumn:@"departure_time"];
		
		NSNumber *arrivalTime = [NSNumber numberWithInt:arrivalInt];
		NSNumber *departureTime = [NSNumber numberWithInt:departureInt];
		
		GRTStopTime *stopTime = [[GRTStopTime alloc] initWithTripId:tripId stopSequence:stopSequence stopId:stopId arrivalTime:arrivalTime departureTime:departureTime];
		[stopTimes addObject:stopTime];
	}
	
	[result close];
	
	return stopTimes;
}

@end
