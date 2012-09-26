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
	NSDate *start = [NSDate date];
	NSArray *stopTimes = [self fetchStopTimesForDate:date];
	NSDate *end = [NSDate date];
	NSLog(@"Time elapsed: %f", end.timeIntervalSince1970 - start.timeIntervalSince1970);
	
	return stopTimes;
}

- (NSArray *)stopTimesForDate:(NSDate *)date andRoute:(GRTRoute *)route;
{
	NSArray *allTimes = [self stopTimesForDate:date];
	NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"trip.route.routeId"] rightExpression:[NSExpression expressionForConstantValue:route.routeId] modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
	NSArray *filteredTimes = [allTimes filteredArrayUsingPredicate:predicate];
	return filteredTimes;
}

- (NSArray *)routesForDate:(NSDate *)date
{
//	NSArray *allTimes = [self stopTimesForDate:date];
	return nil; // TODO
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

- (NSArray *)fetchStopTimesForDate:(NSDate *)date
{
	// prepare data for query
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComps = [calendar components:NSWeekdayCalendarUnit fromDate:date];
	
	NSUInteger dayInWeek = dateComps.weekday;
	NSString *dayName = [self dayNameForDayInWeek:dayInWeek];
	NSNumber *stopId = self.stop.stopId;
	NSString *query = [NSString stringWithFormat:@"SELECT S.* \
					   FROM Calendar as C, Trip as T, StopTime as S \
					   WHERE C.%@ AND S.stopId=? AND \
					   S.tripId=T.tripId AND T.serviceId=C.serviceId \
					   ORDER BY S.departureTime", dayName];
	
	// execute database query
	FMDatabase *db = [GRTGtfsSystem defaultGtfsSystem].db;
	FMResultSet *result = [db executeQuery:query, stopId];
	if (result == nil){
		NSLog(@"%@", [db lastErrorMessage]);
		abort();
	}
	
	// process the data
	NSMutableArray *stopTimes = [[NSMutableArray alloc] init];
	while ([result next]) {
		//retrieve values for each record
		NSNumber *tripId = [NSNumber numberWithInt:[result intForColumn:@"tripId"]];
		NSNumber *arrivalTime = [NSNumber numberWithInt:[result intForColumn:@"arrivalTime"]];
		NSNumber *departureTime = [NSNumber numberWithInt:[result intForColumn:@"departureTime"]];
		
		GRTStopTime *stopTime = [[GRTStopTime alloc] initWithTripId:tripId arrivalTime:arrivalTime departureTime:departureTime];
		[stopTimes addObject:stopTime];
	}
	
	NSLog(@"Obtain %d stopTimes", [stopTimes count]);
	
	return stopTimes;
}

@end
