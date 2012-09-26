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

@property (nonatomic, copy) GRTStop *stop;
@property (nonatomic, strong, readonly) NSArray *stopTimes;

@end

@implementation GRTStopTimes

@synthesize stop = _stop;
@synthesize stopTimes = _stopTimes;

- (NSArray *)stopTimes
{
	if (_stopTimes == nil) {
		_stopTimes = [self fetchStopTimes];
	}
	return _stopTimes;
}

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
	// prepare data for query
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComps = [calendar components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
	
	NSUInteger dayInWeek = dateComps.weekday;
	NSString *dayName = [self dayNameForDayInWeek:dayInWeek];
//	NSNumber *dateAsNumber = [NSNumber numberWithInteger:dateComps.year * 10000 + dateComps.month * 100 + dateComps.day];
	
	NSString *keyPath = [NSString stringWithFormat:@"trip.service.%@", dayName];
	
	NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:keyPath] rightExpression:[NSExpression expressionForConstantValue:[NSNumber numberWithBool:YES]] modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
	
	NSArray *filteredTimes = [self.stopTimes filteredArrayUsingPredicate:predicate];
	
	return filteredTimes;
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

- (NSArray *)fetchStopTimes
{	
	// execute database query
	FMDatabase *db = [GRTGtfsSystem defaultGtfsSystem].db;
	
	FMResultSet *result = [db executeQueryWithFormat:@"SELECT S.tripId, S.arrivalTime, S.departureTime \
						   FROM StopTime as S \
						   WHERE S.stopId=%@ \
						   ORDER BY S.departureTime", self.stop.stopId];
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
		//		NSLog(@"Route %@ %@ leaving at %@", newEntry.routeId, newEntry.tripHeadsign, newEntry.departureTime);
	}
	
	return stopTimes;
}


@end
