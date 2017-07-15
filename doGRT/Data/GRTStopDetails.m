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

- (NSArray *)stopTimesForDate:(NSDate *)date
{
	return [self stopTimesForDate:date andRoute:nil];
}

- (NSArray *)stopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route
{
    NSArray *stopTimes = [self fetchStopTimesForDate:[self yesterdayOfDate:date] andRoute:route thatDepartAfterMidnight:YES];
    stopTimes = [stopTimes arrayByAddingObjectsFromArray:[self fetchStopTimesForDate:date andRoute:route thatDepartAfterMidnight:NO]];

    NSLog(@"Fetching for date %@ and route %@, obtained %lu stopTimes", date, route, (unsigned long)[stopTimes count]);

    return stopTimes;
}

- (NSArray *)routes
{
	return [self fetchRoutes];
}

#pragma mark - data fetching logic

- (NSDate *)yesterdayOfDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    return [calendar dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:date options:0];
}

- (NSUInteger)dayInWeekForDate:(NSDate *)date
{
	// prepare data for query
	NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	NSDateComponents *dateComps = [calendar components:NSCalendarUnitWeekday fromDate:date];
	
	NSUInteger dayInWeek = dateComps.weekday;
	
	return dayInWeek;
}

- (NSString *)queryValueForDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return [NSString stringWithFormat:@"%04ld%02ld%02ld", (long)dateComps.year, (long)dateComps.month, (long)dateComps.day];
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

- (NSArray *)fetchStopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route thatDepartAfterMidnight:(BOOL)afterMidnight
{
    NSString *dayName = [self dayNameForDayInWeek:[self dayInWeekForDate:date]];
    NSString *dateValue = [self queryValueForDate:date];
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT s.* "
                       @"FROM trips AS t, stop_times AS s "
                       @"WHERE s.stop_id=? AND s.trip_id=t.trip_id AND ("
                       @"  ("
                       @"    EXISTS ("
                       @"      SELECT * FROM calendar_dates AS cd1 "
                       @"      WHERE cd1.date=? AND t.service_id=cd1.service_id AND cd1.exception_type=1"
                       @"    ) OR"
                       @"    ("
                       @"      EXISTS ("
                       @"        SELECT * FROM calendar as c"
                       @"        WHERE c.%@ AND c.service_id=t.service_id"
                       @"      ) AND"
                       @"      NOT EXISTS ("
                       @"        SELECT * FROM calendar_dates AS cd2 "
                       @"        WHERE cd2.date=? AND t.service_id=cd2.service_id AND cd2.exception_type=2"
                       @"      )"
                       @"    )"
                       @"  )"
                       @") ",
					   dayName];
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:self.stop.stopId, dateValue, dateValue, nil];
    NSLog(@"Querying %@ with args %@", query, arguments);

	if (afterMidnight) {
		query = [query stringByAppendingFormat:@"AND s.departure_time>=? "];
		[arguments addObject:[NSNumber numberWithInt:240000]];
	}
	
	if (route != nil) {
		query = [query stringByAppendingString:@"AND t.route_id=? "];
		[arguments addObject:route.routeId];
	}
	query = [query stringByAppendingString:@"ORDER BY s.departure_time "];
	
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
		if (afterMidnight) {
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
	NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT t.route_id \
					   FROM trips AS t, stop_times AS s \
					   WHERE s.stop_id=? AND s.trip_id=t.trip_id \
					   ORDER BY t.route_id"];
	
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
