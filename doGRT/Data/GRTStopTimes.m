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
	NSArray *stopTimes = [self fetchStopTimesForDate:date andRoute:nil];
	
	return stopTimes;
}

- (NSArray *)stopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route;
{
	NSArray *stopTimes = [self fetchStopTimesForDate:date andRoute:route];
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

- (NSArray *)fetchStopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route
{
	// prepare data for query
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComps = [calendar components:NSWeekdayCalendarUnit fromDate:date];
	
	NSUInteger dayInWeek = dateComps.weekday;
	NSString *dayName = [self dayNameForDayInWeek:dayInWeek];
	
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:self.stop.stopId];
	NSString *query = [NSString stringWithFormat:@"SELECT S.* \
					   FROM Calendar as C, Trip as T, StopTime as S \
					   WHERE C.%@ AND S.stopId=? AND \
					   S.tripId=T.tripId AND T.serviceId=C.serviceId ",
					   dayName];
	
	if (route != nil) {
		query = [query stringByAppendingString:@"AND T.routeId=? "];
		[arguments addObject:route.routeId];
	}
	query = [query stringByAppendingString:@"ORDER BY S.departureTime "];
	
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
		NSNumber *tripId = [NSNumber numberWithInt:[result intForColumn:@"tripId"]];
		NSNumber *stopSequence = [NSNumber numberWithInt:[result intForColumn:@"stopSequence"]];
		NSNumber *stopId = [NSNumber numberWithInt:[result intForColumn:@"stopId"]];
		NSNumber *arrivalTime = [NSNumber numberWithInt:[result intForColumn:@"arrivalTime"]];
		NSNumber *departureTime = [NSNumber numberWithInt:[result intForColumn:@"departureTime"]];
		
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
	NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT T.routeId \
					   FROM Trip as T, StopTime as S \
					   WHERE S.stopId=? AND S.tripId=T.tripId \
					   ORDER BY T.routeId"];
	
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
		NSNumber *routeId = [NSNumber numberWithInt:[result intForColumn:@"routeId"]];
		GRTRoute *route = [[GRTGtfsSystem defaultGtfsSystem] routeById:routeId];
		if (route != nil) {
			[routes addObject:route];
		}
	}
	
	[result close];
	return routes;
}

@end
