//
//  GRTStopTimes.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTStopTimes.h"
#import "GRTGtfsSystem+Internal.h"

#import "FMDatabase.h"

@interface GRTStopTimes ()

@property (nonatomic, strong) GRTStop *stop;

@end

@implementation GRTStopTimes

@synthesize stop = _stop;

#pragma mark - constructor

- (GRTStopTimes *)initWithStop:(GRTStop *)stop
{
	self = [super init];
	if (self != nil) {
		self.stop = stop;
	}
	return self;
}

#pragma mark - data access

- (NSArray *)stopTimesForDate:(NSDate *)date
{
	
	NSArray *stopTimes = [self fetchDawnStopTimesForDate:date andRoute:nil];
	stopTimes = [stopTimes arrayByAddingObjectsFromArray:[self fetchStopTimesForDate:date andRoute:nil]];
	
	return stopTimes;
}

- (NSArray *)stopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route
{
	NSArray *stopTimes = [self fetchDawnStopTimesForDate:date andRoute:route];
	stopTimes = [stopTimes arrayByAddingObjectsFromArray:[self fetchStopTimesForDate:date andRoute:route]];
	return stopTimes;
}

- (NSArray *)routes
{
	return [self fetchRoutes];
}

#pragma mark - data fetching logic

- (NSString *)dayNameForDayInWeek:(NSUInteger)dayInWeek
{
	NSString *dayName = nil;
	if(dayInWeek == 1) dayName = @"sunday";
	else if(dayInWeek == 2) dayName = @"monday";
	else if(dayInWeek == 3) dayName = @"tuesday";
	else if(dayInWeek == 4) dayName = @"wednesday";
	else if(dayInWeek == 5) dayName = @"thursday";
	else if(dayInWeek == 6) dayName = @"friday";
	else if(dayInWeek == 7) dayName = @"saturday";
	return dayName;
}

- (NSArray *)fetchDawnStopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route
{
	// prepare data for query
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComps = [calendar components:NSWeekdayCalendarUnit fromDate:[NSDate dateWithTimeInterval:-86400 sinceDate:date]];
	
	NSUInteger dayInWeek = dateComps.weekday;
	NSString *dayName = [self dayNameForDayInWeek:dayInWeek];
	
	NSString *query = [NSString stringWithFormat:@"SELECT S.* \
					   FROM calendar as C, trips as T, stop_times as S \
					   WHERE C.%@ AND S.stop_id=? AND \
					   S.departure_time>=? AND \
					   S.trip_id=T.trip_id AND T.service_id=C.service_id ",
					   dayName];
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:self.stop.stopId, [NSNumber numberWithInt:240000], nil];
	
	if (route != nil) {
		query = [query stringByAppendingString:@"AND T.route_id=? "];
		[arguments addObject:route.routeId];
	}
	query = [query stringByAppendingString:@"ORDER BY S.departure_time "];
	
	// execute database query
	FMDatabase *db = [GRTGtfsSystem defaultGtfsSystem].db;
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
		NSNumber *arrivalTime = [NSNumber numberWithInt:[result intForColumn:@"arrival_time"]];
		NSNumber *departureTime = [NSNumber numberWithInt:[result intForColumn:@"departure_time"]];
		
		GRTStopTime *stopTime = [[GRTStopTime alloc] initWithTripId:tripId stopSequence:stopSequence stopId:stopId arrivalTime:arrivalTime departureTime:departureTime];
		[stopTimes addObject:stopTime];
	}
	
	NSLog(@"Obtain %d stopTimes", [stopTimes count]);
	
	[result close];
	
	return stopTimes;
}

- (NSArray *)fetchStopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route
{
	// prepare data for query
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComps = [calendar components:NSWeekdayCalendarUnit fromDate:date];
	
	NSUInteger dayInWeek = dateComps.weekday;
	NSString *dayName = [self dayNameForDayInWeek:dayInWeek];
	
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:self.stop.stopId];
	NSString *query = [NSString stringWithFormat:@"SELECT S.* \
					   FROM calendar as C, trips as T, stop_times as S \
					   WHERE C.%@ AND S.stop_id=? AND \
					   S.trip_id=T.trip_id AND T.service_id=C.service_id ",
					   dayName];
	
	if (route != nil) {
		query = [query stringByAppendingString:@"AND T.route_id=? "];
		[arguments addObject:route.routeId];
	}
	query = [query stringByAppendingString:@"ORDER BY S.departure_time "];
	
	// execute database query
	FMDatabase *db = [GRTGtfsSystem defaultGtfsSystem].db;
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
		NSNumber *arrivalTime = [NSNumber numberWithInt:[result intForColumn:@"arrival_time"]];
		NSNumber *departureTime = [NSNumber numberWithInt:[result intForColumn:@"departure_time"]];
		
		GRTStopTime *stopTime = [[GRTStopTime alloc] initWithTripId:tripId stopSequence:stopSequence stopId:stopId arrivalTime:arrivalTime departureTime:departureTime];
		[stopTimes addObject:stopTime];
	}
	
	NSLog(@"Obtain %d stopTimes", [stopTimes count]);
	
	[result close];
	
	return stopTimes;
}

- (NSArray *)fetchRoutes
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:self.stop.stopId];
	NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT T.route_id \
					   FROM trips as T, stop_times as S \
					   WHERE S.stop_id=? AND S.trip_id=T.trip_id \
					   ORDER BY T.route_id"];
	
	// execute database query
	FMDatabase *db = [GRTGtfsSystem defaultGtfsSystem].db;
	FMResultSet *result = [db executeQuery:query withArgumentsInArray:arguments];
	if (result == nil){
		NSLog(@"%@", [db lastErrorMessage]);
		abort();
	}
	
	// process the data
	NSMutableArray *routes = [[NSMutableArray alloc] init];
	while ([result next]) {
		NSNumber *routeId = [NSNumber numberWithInt:[result intForColumn:@"route_id"]];
		GRTRoute *route = [[GRTGtfsSystem defaultGtfsSystem] routeById:routeId];
		if (route != nil) {
			[routes addObject:route];
		}
	}
	
	[result close];
	return routes;
}

@end
