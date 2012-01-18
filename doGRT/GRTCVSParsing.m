//
//  GRTCVSParsing.m
//  doGRT
//
//  Created by Greg Wang on 12-1-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTCVSParsing.h"
#import "BusStop.h"
#import "Calendar.h"
#import "Route.h"
#import "StopTime.h"
#import "Trip.h"

@interface GRTCVSParsing ()
- (BOOL) parseFromURL:(NSURL *)absoluteURL 
			forEntity:(NSString *)entity 
		  withMapping:(NSDictionary *)mapping
	  withTypeMapping:(NSDictionary *)typeMapping
				error:(NSError **)outError;
@end

@implementation GRTCVSParsing

@synthesize managedObjectContext = _managedObjectContext;

- (GRTCVSParsing *) init {
	self = [super init];
	if(self){
		self.managedObjectContext = [(id) [[UIApplication sharedApplication] delegate] managedObjectContext];
	}
	return self;
}

- (NSNumber *)timeWithString:(NSString *)string{
	NSInteger hour = [[string substringToIndex:2] integerValue];
	NSInteger minute = [[string substringWithRange:NSRangeFromString(@"3 2")] integerValue];
	NSInteger second = [[string substringFromIndex:6] integerValue];
	
	return [NSNumber numberWithInteger:hour * 10000 + minute * 100 + second];
}

- (BOOL) parseCalendar{
	NSString *filePath = [[NSBundle mainBundle] 
						  pathForResource:@"calendar" 
						  ofType:@"txt"]; 
	
	NSError *err = nil;
	BOOL result = [self parseFromURL:[NSURL fileURLWithPath:filePath] 
						   forEntity:@"Calendar" 
						 withMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"serviceId",@"service_id",
									  @"startDate",@"start_date",
									  @"endDate",@"end_date",
									  @"monday",@"monday",
									  @"tuesday",@"tuesday",
									  @"wednesday",@"wednesday",
									  @"thursday",@"thursday",
									  @"friday",@"friday",
									  @"saturday",@"saturday",
									  @"sunday",@"sunday", nil] 
					 withTypeMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"string",@"service_id",
									  @"integer",@"start_date",
									  @"integer",@"end_date",
									  @"bool",@"monday",
									  @"bool",@"tuesday",
									  @"bool",@"wednesday",
									  @"bool",@"thursday",
									  @"bool",@"friday",
									  @"bool",@"saturday",
									  @"bool",@"sunday", nil] 
							   error:&err];
	return result;
}

- (BOOL) parseRoutes{
	NSString *filePath = [[NSBundle mainBundle] 
						  pathForResource:@"routes" 
						  ofType:@"txt"]; 
	
	NSError *err = nil;
	BOOL result = [self parseFromURL:[NSURL fileURLWithPath:filePath] 
						   forEntity:@"Route" 
						 withMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"routeId",@"route_id",
									  @"routeLongName",@"route_long_name",
									  @"routeShortName",@"route_short_name", nil] 
					 withTypeMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"string",@"route_id",
									  @"string",@"route_long_name",
									  @"string",@"route_short_name", nil]
							   error:&err];
	return result;
}

- (BOOL) parseStopTimes{
	NSString *filePath = [[NSBundle mainBundle] 
						  pathForResource:@"stop_times" 
						  ofType:@"txt"]; 
	
	NSError *err = nil;
	BOOL result = [self parseFromURL:[NSURL fileURLWithPath:filePath] 
						   forEntity:@"StopTime" 
						 withMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"tripId",@"trip_id",
									  @"arrivalTime",@"arrival_time",
									  @"departureTime",@"departure_time",
									  @"stopId",@"stop_id",
									  @"stopSequence",@"stop_sequence", nil] 
					 withTypeMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"string",@"trip_id",
									  @"time",@"arrival_time",
									  @"time",@"departure_time",
									  @"integer",@"stop_id",
									  @"integer",@"stop_sequence", nil] 
							   error:&err];
	return result;
}

- (BOOL) parseStops{
	NSString *filePath = [[NSBundle mainBundle] 
						  pathForResource:@"stops" 
						  ofType:@"txt"]; 
	
	NSError *err = nil;
	BOOL result = [self parseFromURL:[NSURL fileURLWithPath:filePath] 
						   forEntity:@"BusStop" 
						 withMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"stopLat",@"stop_lat",
									  @"stopLon",@"stop_lon",
									  @"stopId",@"stop_id",
									  @"stopName",@"stop_name", nil] 
					 withTypeMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"double",@"stop_lat",
									  @"double",@"stop_lon",
									  @"integer",@"stop_id",
									  @"string",@"stop_name", nil] 
							   error:&err];
	return result;
}

- (BOOL) parseTrips{
	NSString *filePath = [[NSBundle mainBundle] 
						  pathForResource:@"trips" 
						  ofType:@"txt"]; 
	
	NSError *err = nil;
	BOOL result = [self parseFromURL:[NSURL fileURLWithPath:filePath] 
						   forEntity:@"Trip" 
						 withMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"routeId", @"route_id",
									  @"tripHeadsign",@"trip_headsign",
									  @"serviceId",@"service_id",
									  @"tripId",@"trip_id", nil] 
					 withTypeMapping:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"string", @"route_id",
									  @"string",@"trip_headsign",
									  @"string",@"service_id",
									  @"string",@"trip_id", nil]  
							   error:&err];
	return result;
}

- (BOOL) parseAll{
	return [self parseStops] && 
	[self parseCalendar] &&
	[self parseRoutes] &&
	[self parseStopTimes] &&
	[self parseTrips];
}

- (BOOL) parseFromURL:(NSURL *)absoluteURL 
			forEntity:(NSString *)entity 
		  withMapping:(NSDictionary *)mapping
	  withTypeMapping:(NSDictionary *)typeMapping
				error:(NSError **)outError {
	
	// Open file into fileString
	NSString *fileString = [NSString stringWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error:outError];
	if(fileString == nil) {
		NSLog(@"Fail to open fileString, with url %@", absoluteURL);
		return NO;
	}
	
	// Setup scanner
	NSScanner *scanner = [NSScanner scannerWithString:fileString];
	scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@""];
	NSCharacterSet *seperationSet = [NSCharacterSet characterSetWithCharactersInString:@"\n,"];
	
	// Buffer value, flag variables, header array, colume number counter, managed object
	NSString *value;
	id newValue;
	BOOL gotValue, gotComma, gotLF, isFirstLine = YES;
	NSMutableArray *header = [[NSMutableArray alloc] init];
	NSUInteger colNum = 0;
	NSManagedObject *object = nil;
	
	// Start reading
	while([scanner isAtEnd] == NO){
		// read a token
		gotValue = [scanner scanUpToCharactersFromSet:seperationSet intoString:&value];
		gotComma = [scanner scanString:@"," intoString:nil];
		gotLF = [scanner scanString:@"\n" intoString:nil];
		
		// if is first line, save into header
		if(isFirstLine){
			[header addObject:value];
			if (gotLF) {
				isFirstLine = NO;
			}
		}
		// else if it is an attribute mapping into the entity
		else if([mapping objectForKey:[header objectAtIndex:colNum]]) {
//			NSLog(@"Get token %@ for colum %@ mapping to %@", 
//				  value, [header objectAtIndex:colNum], [mapping objectForKey:[header objectAtIndex:colNum]]);
			
			// if the object doesn't exists, create one
			if(object == nil){
				object = (NSManagedObject *)[NSEntityDescription 
									  insertNewObjectForEntityForName:entity 
									  inManagedObjectContext:self.managedObjectContext];
				if(object == nil){
					NSLog(@"Creating new object failed");
					return NO;
				}
			}
			
			// set the new value to old value first and then try to convert
			newValue = value;
			NSString *type = [typeMapping objectForKey:[header objectAtIndex:colNum]];
			if(type == @"integer"){
				newValue = [NSNumber numberWithInteger:[value integerValue]];
			}
			else if(type == @"double"){
				newValue = [NSNumber numberWithDouble:[value doubleValue]];
			}
			else if(type == @"bool"){
				newValue = [NSNumber numberWithBool:[value boolValue]];
			}
			else if(type == @"time"){
				newValue = [self timeWithString:value];
			}
			
			// save value into the object
			[object setValue:newValue 
					  forKey:[mapping objectForKey:[header objectAtIndex:colNum]]];
			value = nil;
		}
		
		// colume number increament
		if(gotLF){
//			NSLog(@"Object Finish as %@", object);
			colNum = 0;
			object = nil;
		}
		else{
			colNum++;
		}
	}
	
	// Save changes
	NSLog(@"Saving new objects for entity: %@", entity);
	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		// Handle the error.
		NSLog(@"Saving failed");
		return NO;
	}
	
	NSLog(@"CVS parsing finish with header %@, mapping %@, type mapping %@", 
		  header, mapping, typeMapping);
	
	return YES;
}

@end
