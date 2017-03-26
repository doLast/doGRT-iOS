//
//  GRTStopTimes.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTStopDetails.h"
#import "GRTGtfsSystem+Internal.h"

#import "FMDatabase.h"
#import "GRTUserProfile.h"

@interface GRTStopDetails ()

@property (nonatomic, strong) GRTStop *stop;

@end

@implementation GRTStopDetails

@synthesize stop = _stop;

#pragma mark - constructor

- (GRTStopDetails *)initWithStop:(GRTStop *)stop
{
	self = [super init];
	if (self != nil) {
		self.stop = stop;
	}
	return self;
}

#pragma mark - data access

- (NSArray *)stopTimesForDayInWeek:(NSUInteger)dayInWeek
{
	return [self stopTimesForDayInWeek:dayInWeek andRoute:nil];
}

- (NSArray *)stopTimesForDayInWeek:(NSUInteger)dayInWeek andRoute:(GRTRoute *)route
{
	NSArray *stopTimes = [self fetchStopTimesForDay:dayInWeek - 1 andRoute:route drawOnly:YES];
	stopTimes = [stopTimes arrayByAddingObjectsFromArray:[self fetchStopTimesForDay:dayInWeek andRoute:route drawOnly:NO]];
	
	NSLog(@"Fetching for day #%d and route %@, obtained %d stopTimes", dayInWeek, route, [stopTimes count]);
	
	return stopTimes;
}

- (NSArray *)stopTimesForDate:(NSDate *)date
{
	return [self stopTimesForDayInWeek:[self dayInWeekForDate:date]];
}

- (NSArray *)stopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route
{
	return [self stopTimesForDayInWeek:[self dayInWeekForDate:date] andRoute:route];
}

- (NSArray *)routes
{
	return [self fetchRoutes];
}

#pragma mark - data fetching logic

- (NSUInteger)dayInWeekForDate:(NSDate *)date
{
	// prepare data for query
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComps = [calendar components:NSWeekdayCalendarUnit fromDate:date];
	
	NSUInteger dayInWeek = dateComps.weekday;
	
	return dayInWeek;
}

- (NSString *)dayNameForDayInWeek:(NSUInteger)dayInWeek
{
	NSString *dayName = nil;
	if(dayInWeek == 0) dayName = @"saturday";
	else if(dayInWeek == 1) dayName = @"sunday";
	else if(dayInWeek == 2) dayName = @"monday";
	else if(dayInWeek == 3) dayName = @"tuesday";
	else if(dayInWeek == 4) dayName = @"wednesday";
	else if(dayInWeek == 5) dayName = @"thursday";
	else if(dayInWeek == 6) dayName = @"friday";
	else if(dayInWeek == 7) dayName = @"saturday";
	return dayName;
}

- (NSArray *)fetchStopTimesForDay:(NSUInteger)day andRoute:(GRTRoute *)route drawOnly:(BOOL)drawOnly
{
	NSString *dayName = [self dayNameForDayInWeek:day];
	NSString *query = [NSString stringWithFormat:@"SELECT S.* \
					   FROM calendar as C, trips as T, stop_times as S \
					   WHERE C.%@ AND S.stop_id=? AND \
					   S.trip_id=T.trip_id AND T.service_id=C.service_id ",
					   dayName];
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:self.stop.stopId];

	if (drawOnly) {
		query = [query stringByAppendingFormat:@"AND S.departure_time>=? "];
		[arguments addObject:[NSNumber numberWithInt:240000]];
	}
	
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
	BOOL displayTerminusStopTimes = [[[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserDisplayTerminusStopTimesPreference] boolValue];
	NSMutableArray *stopTimes = [[NSMutableArray alloc] init];
	while ([result next]) {
		//retrieve values for each record
		NSNumber *tripId = [NSNumber numberWithInt:[result intForColumn:@"trip_id"]];
		NSNumber *stopSequence = [NSNumber numberWithInt:[result intForColumn:@"stop_sequence"]];
		NSNumber *stopId = [NSNumber numberWithInt:[result intForColumn:@"stop_id"]];
		NSInteger arrivalInt = [result intForColumn:@"arrival_time"];
		NSInteger departureInt = [result intForColumn:@"departure_time"];
		if (drawOnly) {
			arrivalInt -= 240000;
			departureInt -= 240000;
		}
		NSNumber *arrivalTime = [NSNumber numberWithLong:arrivalInt];
		NSNumber *departureTime = [NSNumber numberWithLong:departureInt];
		
		GRTStopTime *stopTime = [[GRTStopTime alloc] initWithTripId:tripId stopSequence:stopSequence stopId:stopId arrivalTime:arrivalTime departureTime:departureTime];
		if (!displayTerminusStopTimes &&
			[stopTime.stopSequence integerValue] == stopTime.trip.totalStops) {
		} else {
			[stopTimes addObject:stopTime];
		}
	}
	
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
