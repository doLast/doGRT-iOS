//
//  GRTBusInfo.m
//  doGRT
//
//  Created by Greg Wang on 12-1-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTBusInfo.h"
#import "BusStop.h"
#import "Calendar.h"
#import "Route.h"
#import "StopTime.h"
#import "Trip.h"

#import "GRTTimeTableEntry.h"

@implementation GRTBusInfo

@synthesize managedObjectContext = _managedObjectContext;

- (GRTBusInfo *) init {
	self = [super init];
	if(self){
		self.managedObjectContext = [(id) [[UIApplication sharedApplication] delegate] managedObjectContext];
	}
	return self;
}

- (NSArray *) getBusStopsAt:(CLLocationCoordinate2D)coordinate 
					 inSpan:(MKCoordinateSpan)span 
				  withLimit:(NSUInteger)limit{
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BusStop"];
	
	NSNumber *latitudeStart = [NSNumber numberWithDouble:coordinate.latitude - span.latitudeDelta/2.0];
    NSNumber *latitudeStop = [NSNumber numberWithDouble:coordinate.latitude + span.latitudeDelta/2.0];
    NSNumber *longitudeStart = [NSNumber numberWithDouble:coordinate.longitude - span.longitudeDelta/2.0];
    NSNumber *longitudeStop = [NSNumber numberWithDouble:coordinate.longitude + span.longitudeDelta/2.0];
	
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stopLat>%@ AND stopLat<%@ AND stopLon>%@ AND stopLon<%@", latitudeStart, latitudeStop, longitudeStart, longitudeStop];
    [request setPredicate:predicate];
	
	[request setFetchLimit:limit];
	
	NSError *error = nil;
	NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request 
																	 error:&error];
	if (fetchResults == nil) {
		// Handle the error.
	}
	
	return  fetchResults;
	
	// return an array of BusStop
}

- (NSString *) getBusStopNameById:(NSNumber *)stopId{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BusStop"];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stopId=%@", stopId];
	[request setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request 
																	 error:&error];
	
	if (fetchResults == nil){
		// Handle the error.
	}
	
	if ([fetchResults count] > 1){
		NSLog(@"Getting %d bus stop entries by stopId %@", [fetchResults count], stopId);
	}
	else if([fetchResults count] == 0){
		return nil;
	}
	return [(BusStop *)[fetchResults objectAtIndex:0] stopName];
}

- (NSArray *) getCurrentTimeTableById:(NSNumber *)stopId{
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
	
	NSLog(@"CurrentTime %d", cutTime);
	
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

- (NSArray *) getTimeTableById:(NSNumber *)stopId forDate:(NSDate *)date{
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
	
- (NSArray *) getTimeTableById:(NSNumber *)stopId 
						forDay:(NSString *)day 
					   andDate:(NSUInteger)date
					 withLimit:(NSUInteger)limit{
	NSFetchRequest *request = nil;
	NSArray *predArray = nil;
	NSPredicate *predicate = nil;
	NSError *error = nil;
	NSLog(@"Getting time table by id:%@, limit:%d", stopId, limit);
	
	// Finding all trips that pass by the stop
	request = [NSFetchRequest fetchRequestWithEntityName:@"StopTime"];
	[request setPropertiesToFetch:[NSArray arrayWithObjects:@"tripId", nil]];
	[request setReturnsDistinctResults:YES];
	[request setPredicate:[NSPredicate predicateWithFormat:@"stopId=%@", stopId]];

	NSArray *tripsPassByStop = [self.managedObjectContext executeFetchRequest:request 
																		error:&error];
	if (tripsPassByStop == nil) {
		// Handle the error.
	}
	if ([tripsPassByStop count] == 0){
		return nil;
	}
//	NSLog(@"Get trips that pass by the stop: ");
//	for (StopTime *trip in tripsPassByStop) {
//		NSLog(@"TripId: %@", trip.tripId);
//	}
	
	// Find the services available on the day, get an array of Calendar
	request = [NSFetchRequest fetchRequestWithEntityName:@"Calendar"];
	predicate = [NSPredicate predicateWithFormat:@"%K=YES AND startDate<=%d AND endDate>=%d", day, date, date];
	[request setPredicate:predicate];
//	NSLog(@"Finding today available services predicate: %@", predicate);
	
	NSArray *servicesAvailableToday = 
		[self.managedObjectContext executeFetchRequest:request error:&error];
	if (servicesAvailableToday == nil){
		// Handle the error.
		abort();
	}
	if([servicesAvailableToday count] == 0){
		// No available service found
		NSLog(@"No available service found");
		return nil;
	}
//	NSLog(@"Services available at today are:");
//	for (Calendar *cal in servicesAvailableToday) {
//		NSLog(@"Service: %@", cal.serviceId);
//	}
	
	// Construct trip predicate	
	NSMutableArray *tripArray = [[NSMutableArray alloc] init];
	StopTime *aTrip;
	for (aTrip in tripsPassByStop) {
		[tripArray addObject:aTrip.tripId];
	}
	
	// Construct service predicate
	NSMutableArray *serviceArray = [[NSMutableArray alloc] init];
	Calendar *calendarEntry;
	for (calendarEntry in servicesAvailableToday) {
		[serviceArray addObject:calendarEntry.serviceId];
	}
	
	// Find the valid trips
	request = [NSFetchRequest fetchRequestWithEntityName:@"Trip"];
	[request setReturnsDistinctResults:YES];
	
	NSPredicate *tripPred = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"tripId"] rightExpression:[NSExpression expressionForConstantValue:tripArray] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0];
	
	NSPredicate *servicePred = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"serviceId"] rightExpression:[NSExpression expressionForConstantValue:serviceArray] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0];
	predArray = [NSArray arrayWithObjects:tripPred, servicePred, nil];
	
	predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
	[request setPredicate:predicate];
//	NSLog(@"Finding valid trips predicate:%@", predicate);
	
	NSArray *tripsAvailableToday = [self.managedObjectContext executeFetchRequest:request 
																			error:&error];
	if (tripsAvailableToday == nil) {
		// Handle the error.
	}
	if ([tripsAvailableToday count] == 0){
		return nil;
	}
	NSMutableDictionary *tripDict = [[NSMutableDictionary alloc] initWithCapacity:[tripsAvailableToday count]];
	for (Trip *trip in tripsAvailableToday){
		[tripDict setValue:trip forKey:trip.tripId];
	}	
//	NSLog(@"Get valid trips today by the stop: ");
//	for (Trip *trip in tripsAvailableToday) {
//		NSLog(@"TripId: %@", trip.tripId);
//	}
	
	// Get the time table for today
	request = [NSFetchRequest fetchRequestWithEntityName:@"StopTime"];
	
	[request setPropertiesToFetch:[NSArray arrayWithObjects:@"tripId", @"arrivalTime", @"departureTime", nil]];
	[request setReturnsDistinctResults:YES];
	
//	NSPredicate *stopIdPredicate = [NSPredicate predicateWithFormat:@"stopId = %@ AND arrivalTime>%d", stopId, comps.hour * 10000 + comps.minute * 100 + comps.second - 1000];
	NSPredicate *stopIdPredicate = [NSPredicate predicateWithFormat:@"stopId = %@", stopId];
	NSPredicate *tripIdPredicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"tripId"] rightExpression:[NSExpression expressionForConstantValue:[tripDict allKeys]] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0];
	predArray = [NSArray arrayWithObjects:stopIdPredicate, tripIdPredicate, nil];
	
	predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predArray];
	[request setPredicate:predicate];
//	NSLog(@"Finding time table predicate:%@", predicate);
	
	if (limit != 0) [request setFetchLimit:limit];
	
	NSArray *timeTableResult = [self.managedObjectContext executeFetchRequest:request 
																		error:&error];
	if (timeTableResult == nil) {
		// Handle the error.
	}
	if ([timeTableResult count] == 0){
		return nil;
	}
	
//	NSLog(@"Finish fetching time table, get %d items", [timeTableResult count]);
	
	NSMutableArray *timeTable = [[NSMutableArray alloc] initWithCapacity:[timeTableResult count]];
	for (StopTime *time in timeTableResult){
		Trip *trip = [tripDict objectForKey:time.tripId];
		[timeTable addObject:[[GRTTimeTableEntry alloc] initWithRouteId:trip.routeId tripHeadsign:trip.tripHeadsign arrivalTime:time.arrivalTime departureTime:time.departureTime]];
//		NSLog(@"timeTable item: %@, %@, %@, %@", trip.routeId, trip.tripHeadsign, time.arrivalTime, time.departureTime);
	}
	
	NSArray *sortedTimeTable = [timeTable sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"departureTime" ascending:YES]]];
	
//	NSLog(@"Finish sorting time table");
	// return an array of GRTTimeTableEntry
	return sortedTimeTable;
}

@end
