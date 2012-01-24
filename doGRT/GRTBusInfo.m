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

#import "GRTTimeTableEntry.h"
#import "GRTBusStopEntry.h"

@implementation GRTBusInfo

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

+ (NSArray *) getBusStopsAt:(CLLocationCoordinate2D)coordinate 
					 inSpan:(MKCoordinateSpan)span 
				  withLimit:(NSUInteger)limit{
	
	FMDatabase *db = [self openDB];
	
	NSNumber *latitudeStart = [NSNumber numberWithDouble:coordinate.latitude - span.latitudeDelta/2.0];
    NSNumber *latitudeStop = [NSNumber numberWithDouble:coordinate.latitude + span.latitudeDelta/2.0];
    NSNumber *longitudeStart = [NSNumber numberWithDouble:coordinate.longitude - span.longitudeDelta/2.0];
    NSNumber *longitudeStop = [NSNumber numberWithDouble:coordinate.longitude + span.longitudeDelta/2.0];
	
	FMResultSet *result = [db executeQuery:@"SELECT * FROM BusStop WHERE stopLat>? AND stopLat<? AND stopLon>? AND stopLon<? LIMIT ?", latitudeStart, latitudeStop, longitudeStart, longitudeStop, [NSNumber numberWithInt:limit]];
	
	NSMutableArray *busStops = [[NSMutableArray alloc] init];
	while ([result next]){
		GRTBusStopEntry *newStop = [[GRTBusStopEntry alloc] init];
		newStop.stopId = [NSNumber numberWithInt:[result intForColumn:@"stopId"]];
		newStop.stopName = [result stringForColumn:@"stopName"];
		newStop.stopLat = [NSNumber numberWithDouble:[result doubleForColumn:@"stopLat"]];
		newStop.stopLon = [NSNumber numberWithDouble:[result doubleForColumn:@"stopLon"]];
		
		[busStops addObject:newStop];
	}
		
	return busStops;
	// return an array of GRTBusStopEntry
}

+ (NSString *) getBusStopNameById:(NSNumber *)stopId{
	
	FMDatabase *db = [self openDB];
	
	FMResultSet *result = [db executeQuery:@"SELECT stopName FROM BusStop WHERE stopId=?", stopId];
	
	NSString *stopName = nil;
	while ([result next]) {
		//retrieve values for each record
		stopName = [result stringForColumn:@"stopName"];
		NSLog(@"Got stop name %@", stopName);
	}
	
	return stopName;
}

+ (NSArray *) getCurrentTimeTableById:(NSNumber *)stopId{
	
//	NSLog(@"Getting current time table");
	
//	NSArray *yesterday = [self getTimeTableById:stopId forDate:[NSDate dateWithTimeIntervalSinceNow:-86400]];
//	NSArray *today = [self getTimeTableById:stopId forDate:[NSDate date]];
//	yesterday = [yesterday filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departureTime>=230000"]];
	
//	GRTTimeTableEntry *entry = nil;
//	for(entry in yesterday){
//		entry.arrivalTime = [NSNumber numberWithInteger:[entry.arrivalTime integerValue] - 240000];
//		entry.departureTime = [NSNumber numberWithInteger:[entry.departureTime integerValue] - 240000];
//	}
	
	// Get what day is today
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:[NSDate date]];
	NSInteger cutTime = comps.hour * 10000 + comps.minute * 100 + comps.second;
		
	NSArray *table = nil;
	if(cutTime < 10000){
		table = [self getTimeTableById:stopId forDate:[NSDate dateWithTimeIntervalSinceNow:-86400]];
		GRTTimeTableEntry *entry = nil;
		for(entry in table){
			entry.arrivalTime = [NSNumber numberWithInteger:[entry.arrivalTime integerValue] - 240000];
			entry.departureTime = [NSNumber numberWithInteger:[entry.departureTime integerValue] - 240000];
		}
	}
	else {
		table = [self getTimeTableById:stopId forDate:[NSDate date]];
	}
	cutTime -= 3000;
	if(cutTime / 100 % 100 > 60) cutTime -= 4000;
	

	
//	NSArray *combined = [yesterday arrayByAddingObjectsFromArray:today];
//	NSArray *filtered = [combined filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departureTime>=%d", cutTime]];
	NSArray *filtered = [table filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departureTime>=%d", cutTime]];
	
	return filtered;

}

+ (NSArray *) getTimeTableById:(NSNumber *)stopId forDate:(NSDate *)date{
	
//	NSLog(@"Getting time table for date %@", date);
	
	// Get what day for the date
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:date];
	NSUInteger day = comps.weekday;
	NSString *dayName = @"";
	switch (day) {
		case 1:
			dayName = @"sunday";
			break;
		case 2:
			dayName = @"monday";
			break;
		case 3:
			dayName = @"tuesday";
			break;
		case 4:
			dayName = @"wednesday";
			break;
		case 5:
			dayName = @"thursday";
			break;
		case 6:
			dayName = @"friday";
			break;
		case 7:
			dayName = @"saturday";
			break;
		default:
			break;
	}
	NSUInteger dateName = comps.year * 10000 + comps.month * 100 + comps.day;
//	NSLog(@"The day is %@ date is %d", dayName, dateName);
	return [self getTimeTableById:stopId forDay:dayName andDate:dateName withLimit:0];
}
	
+ (NSArray *) getTimeTableById:(NSNumber *)stopId 
						forDay:(NSString *)day 
					   andDate:(NSUInteger)date
					 withLimit:(NSUInteger)limit{
	
	FMDatabase *db = [self openDB];
	
	NSString *query = [NSString stringWithFormat:@"SELECT R.routeId, T.tripHeadsign, S.arrivalTime, S.departureTime FROM Calendar as C, Trip as T, Route as R, StopTime as S WHERE C.%@=1 AND C.startDate<=? AND C.endDate>=? AND T.serviceId=C.serviceId AND S.stopId=? AND S.tripId=T.tripId AND R.routeId=T.routeId", day];
	
	FMResultSet *result = 
	[db executeQuery:query, [NSNumber numberWithInt:date], [NSNumber numberWithInt:date], stopId];
	
	if (result == nil){
		NSLog(@"%@", [db lastErrorMessage]);
		abort();
	}
	
	NSMutableArray *timeTable = [[NSMutableArray alloc] initWithCapacity:100];
	while ([result next]) {
//		NSLog(@"Got next");
		//retrieve values for each record
		GRTTimeTableEntry *newEntry = [[GRTTimeTableEntry alloc] init];
		newEntry.routeId = [NSNumber numberWithInt:[result intForColumn:@"routeId"]];
		newEntry.tripHeadsign = [result stringForColumn:@"tripHeadsign"];
		newEntry.arrivalTime = [NSNumber numberWithInt:[result intForColumn:@"arrivalTime"]];
		newEntry.departureTime = [NSNumber numberWithInt:[result intForColumn:@"departureTime"]];
		[timeTable addObject:newEntry];
//		NSLog(@"Entry Constructed");
//		NSLog(@"Route %@ %@ leaving at %@", newEntry.routeId, newEntry.tripHeadsign, newEntry.departureTime);
	}
		
	NSArray *sortedTimeTable = [timeTable sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"departureTime" ascending:YES]]];
	
	return sortedTimeTable;
}

@end
