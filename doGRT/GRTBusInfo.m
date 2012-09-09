//
//  GRTBusInfo.m
//  doGRT
//
//  Created by Greg Wang on 12-1-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTBusInfo.h"

#import "FMDatabase.h"
#import "FMResultSet.h"

#import "GRTBusStopEntry.h"
#import "GRTTimeTableEntry.h"
#import "GRTTripEntry.h"

@interface GRTBusInfo () 
@property (retain, nonatomic) NSNumber *stopId;
@property (retain, nonatomic) NSMutableDictionary *dateToTimeMapping;

- (NSString *) dayOfWeekToDayName:(NSUInteger)dayOfWeek;
- (NSArray *) fetchDataForDate:(NSDate *)date;
@end

@implementation GRTBusInfo

@synthesize stopId = _stopId;
@synthesize dateToTimeMapping = _dateToTimeMapping;

/* Class Methods */
+ (FMDatabase *) openDB{
	static FMDatabase *db;
	
	if(db == nil || ![db open]){
		NSString *dbURL = [[NSBundle mainBundle] pathForResource:@"GRT_GTFS" ofType:@"sqlite"];
		db = [FMDatabase databaseWithPath:dbURL];
		if (![db open]) {
			NSLog(@"Could not open db.");
			abort();
		}
	}
	
	return db;
}

+ (NSSet *)busStops
{
	static NSSet *stops = nil;

	if(stops == nil){
		NSMutableSet *newStops = [[NSMutableSet alloc] init];
		
		FMDatabase *db = [self openDB];
		
		FMResultSet *result = [db executeQuery:@"SELECT * FROM BusStop"];
		while ([result next]){
			NSNumber *stopId = [NSNumber numberWithInt:[result intForColumn:@"stopId"]];
			NSString *stopName = [result stringForColumn:@"stopName"];
			CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([result doubleForColumn:@"stopLat"], [result doubleForColumn:@"stopLon"]);
			
			GRTBusStopEntry *newStop = [[GRTBusStopEntry alloc] initAtCoordinate:coordinate withStopId:stopId withStopName:stopName];
			
			[newStops addObject:newStop];
		}
		
		stops = newStops;
	}
	assert(stops != nil);
	
	return stops;
}

+ (NSArray *) getBusStopsAt:(CLLocationCoordinate2D)coordinate 
					 inSpan:(MKCoordinateSpan)span 
				  withLimit:(NSUInteger)limit{
	NSSet *stops = [GRTBusInfo busStops];
		
	NSNumber *latitudeStart = [NSNumber numberWithDouble:coordinate.latitude - span.latitudeDelta/2.0];
    NSNumber *latitudeStop = [NSNumber numberWithDouble:coordinate.latitude + span.latitudeDelta/2.0];
    NSNumber *longitudeStart = [NSNumber numberWithDouble:coordinate.longitude - span.longitudeDelta/2.0];
    NSNumber *longitudeStop = [NSNumber numberWithDouble:coordinate.longitude + span.longitudeDelta/2.0];
	
	NSSet *busStops = [stops filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"stopLat>%@ && stopLat<%@ && stopLon>%@ && stopLon<%@", latitudeStart, latitudeStop, longitudeStart, longitudeStop]];
	
	NSArray *stopArray = [busStops allObjects];
	if([stopArray count] > limit){
		NSRange range;
		range.location = 0;
		range.length = limit;
		stopArray = [stopArray subarrayWithRange:range];
	}
		
	return stopArray;
	// return an array of GRTBusStopEntry
}

+ (NSArray *) getBusStopsLike:(NSString *)str{
	NSSet *stops = [GRTBusInfo busStops];
	NSArray *components = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSMutableArray *subpredicates = [NSMutableArray array];

	for (NSString *component in components) {
		if([component length] == 0) { continue; }
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stopId.description contains[cd] %@ || stopName contains[cd] %@", component, component];
		[subpredicates addObject:predicate];
	}
	
	return [[stops filteredSetUsingPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates]] allObjects];
}

+ (NSArray *) getBusStopsByRouteId:(NSString *)routeId
{
	
	NSMutableSet *stops = [[NSMutableSet alloc] init];
	
	FMDatabase *db = [self openDB];
	
	FMResultSet *result = [db executeQuery:@"SELECT DISTINCT B.stopId, B.stopName, B.stopLat, B.stopLon \
						   FROM BusStop as B, Trip as T, StopTime as S \
						   WHERE T.routeId=? AND S.tripId=T.tripId AND B.stopId=S.stopId", routeId];
	
	while ([result next]){
		NSNumber *stopId = [NSNumber numberWithInt:[result intForColumn:@"stopId"]];
		NSString *stopName = [result stringForColumn:@"stopName"];
		CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([result doubleForColumn:@"stopLat"], [result doubleForColumn:@"stopLon"]);
		
		GRTBusStopEntry *stop = [[GRTBusStopEntry alloc] initAtCoordinate:coordinate withStopId:stopId withStopName:stopName];
		
		[stops addObject:stop];
	}
	
	return [stops allObjects];
	// return an array of GRTBusStopEntry
}

+ (NSString *) getBusStopNameByStop:(NSNumber *)stopId
{
	
	FMDatabase *db = [self openDB];
	
	FMResultSet *result = [db executeQuery:@"SELECT stopName FROM BusStop WHERE stopId=?", stopId];
	
	NSString *stopName = nil;
	while ([result next]) {
		// retrieve values for each record
		stopName = [result stringForColumn:@"stopName"];
//		NSLog(@"Got stop name %@", stopName);
	}
	
	return stopName;
}


+ (NSArray *) getTripsByStop:(NSNumber *)stopId
{
	
	static NSMutableDictionary *tripDict = nil;
	if(tripDict == nil){
		tripDict = [[NSMutableDictionary alloc] init];
	}
	if(![tripDict objectForKey:stopId]){
		FMDatabase *db = [self openDB];
		
		FMResultSet *result = [db executeQuery:@"SELECT DISTINCT T.tripHeadsign, R.routeId, R.routeLongName, R.routeShortName FROM Trip as T, Route as R, StopTime as S WHERE S.stopId=? AND S.tripId=T.tripId AND R.routeId=T.routeId", stopId];
		
		NSMutableArray *trips = [[NSMutableArray alloc] init];
		while ([result next]) {
			//retrieve values for each record
			GRTTripEntry *entry = [[GRTTripEntry alloc] init];
//			entry.tripId = [NSNumber numberWithInt:[result intForColumn:@"tripId"]];
			entry.tripHeadsign = [result stringForColumn:@"tripHeadsign"];
			entry.routeId = [result stringForColumn:@"routeId"];
			entry.routeLongName = [result stringForColumn:@"routeLongName"];
			entry.routeShortName = [result stringForColumn:@"routeShortname"];
			[trips addObject:entry];
		}
		
		NSArray *sortedTrips = [trips sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"routeId" ascending:YES]]];
		
		[tripDict setObject:sortedTrips forKey:stopId];
	}
	
	return [tripDict objectForKey:stopId];
}

+ (NSArray *) getRoutesByStop:(NSNumber *)stopId
{
	NSArray *trips = [GRTBusInfo getTripsByStop:stopId];
	NSMutableDictionary *routes = [[NSMutableDictionary alloc] init];
	for (GRTTripEntry *entry in trips) {
		if(![routes objectForKey:entry.routeId]){
			[routes setObject:entry forKey:entry.routeId];
		}
	}
	return [[routes allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"routeId" ascending:YES]]];
}

/* Instance Methods */
- (NSString *) dayOfWeekToDayName:(NSUInteger)dayOfWeek
{
	NSString *dayName = nil;
	if(dayOfWeek == 1) dayName = @"sunday";
	else if(dayOfWeek == 2) dayName = @"monday";
	else if(dayOfWeek == 3) dayName = @"tuesday";
	else if(dayOfWeek == 4) dayName = @"wednesday";
	else if(dayOfWeek == 5) dayName = @"thursday";
	else if(dayOfWeek == 6) dayName = @"friday";
	else if(dayOfWeek == 7) dayName = @"saturday";
	return dayName;
}

- (NSArray *) fetchDataForDate:(NSDate *)date
{
	// prepare data for query
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComps = [calendar components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
	
	NSUInteger dayOfWeek = dateComps.weekday;
	NSString *dayName = [self dayOfWeekToDayName:dayOfWeek];
	NSNumber *dateAsNumber = [NSNumber numberWithInteger:dateComps.year * 10000 + dateComps.month * 100 + dateComps.day];
	
	if([self.dateToTimeMapping objectForKey:dateAsNumber]){
		return [self.dateToTimeMapping objectForKey:dateAsNumber];
	}
	
	// setup database query
	/* Removed line "AND C.startDate<=? AND C.endDate>=? \" */
	FMDatabase *db = [GRTBusInfo openDB];
	NSString *query = [NSString stringWithFormat:@"SELECT R.routeId, R.routeLongName, R.routeShortName, \
					   T.tripHeadsign, S.arrivalTime, S.departureTime \
					   FROM Calendar as C, Trip as T, Route as R, StopTime as S \
					   WHERE C.%@ \
					   AND T.serviceId=C.serviceId AND S.stopId=? \
					   AND S.tripId=T.tripId AND R.routeId=T.routeId \
					   ORDER BY S.departureTime", dayName];
	
	FMResultSet *result = [db executeQuery:query/*, dateAsNumber, dateAsNumber*/, self.stopId];
	if (result == nil){
		NSLog(@"%@", [db lastErrorMessage]);
		abort();
	}
	
	// process the data
	NSMutableArray *timeTableArray = [[NSMutableArray alloc] init];
	while ([result next]) {
		//retrieve values for each record
		GRTTimeTableEntry *timeTableEntry = [[GRTTimeTableEntry alloc] init];
		timeTableEntry.routeId = [result stringForColumn:@"routeId"];
		timeTableEntry.tripHeadsign = [result stringForColumn:@"tripHeadsign"];
		timeTableEntry.arrivalTime = [NSNumber numberWithInt:[result intForColumn:@"arrivalTime"]];
		timeTableEntry.departureTime = [NSNumber numberWithInt:[result intForColumn:@"departureTime"]];
		[timeTableArray addObject:timeTableEntry];
//		NSLog(@"Route %@ %@ leaving at %@", newEntry.routeId, newEntry.tripHeadsign, newEntry.departureTime);
	}
	
	[self.dateToTimeMapping setObject:timeTableArray forKey:dateAsNumber];
	
	return timeTableArray;
}

- (GRTBusInfo *) initByStop:(NSNumber *)stopId
{
	self = [super init];
	if(self){
		// Initialize containers
		self.dateToTimeMapping = [[NSMutableDictionary alloc] init];
		self.stopId = stopId;
	}
	return self;
}

- (NSArray *) getCurrentTimeTable
{
	NSDate *curDate = [NSDate date];
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComps = [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:curDate];
	
	NSInteger time = dateComps.hour * 10000 + dateComps.minute * 100 + dateComps.second;
	
	NSArray *table = [self fetchDataForDate:curDate];
	
	if(time <= 60000){
		NSDate *yesterdayDate = [NSDate dateWithTimeInterval:-86400 sinceDate:curDate];
		NSArray *yesterdayTable = [self fetchDataForDate:yesterdayDate];
		NSArray *morningTable = [yesterdayTable filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departureTime>=233000"]];
		for (GRTTimeTableEntry *entry in morningTable) {
			entry.arrivalTime = [NSNumber numberWithInteger:[entry.arrivalTime integerValue] - 240000];
			entry.departureTime = [NSNumber numberWithInteger:[entry.departureTime integerValue] - 240000];
		}
		table = [morningTable arrayByAddingObjectsFromArray:table];
	}
//	time -= 3000;
//	if(time / 100 % 100 > 60) time -= 4000;
	
//	return [table filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"departureTime>%d", time]]];
	return table;
}

- (NSArray *) getCurrentTimeTableByRoute:(NSString *)routeId{
	return [[self getCurrentTimeTable] filteredArrayUsingPredicate:
			[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"routeId"] rightExpression:[NSExpression expressionForConstantValue:routeId] modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0]];
}



@end
