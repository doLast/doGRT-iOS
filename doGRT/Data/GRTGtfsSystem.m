//
//  GRTGtfsSystem.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTGtfsSystem.h"

#import "FMDatabase.h"

static const int kMaxStopsLimit = 50;

@interface GRTGtfsSystem ()

@property (nonatomic, strong, readonly) FMDatabase *db;
@property (nonatomic, strong, readonly) NSSet *stops;
@property (nonatomic, strong) NSCache *services;
@property (nonatomic, strong) NSCache *routes;
@property (nonatomic, strong) NSCache *trips;
@property (nonatomic, strong) NSCache *shapes;

@end

@implementation GRTGtfsSystem

#pragma mark - getter & setter
@synthesize db = _db;
@synthesize stops = _stops;
@synthesize routes = _routes;
@synthesize trips = _trips;
@synthesize shapes = _shapes;

- (FMDatabase *)db
{
	if (_db == nil) {
		NSString *dbURL = [[NSBundle mainBundle] pathForResource:@"GRT_GTFS" ofType:@"sqlite"];
		_db = [FMDatabase databaseWithPath:dbURL];
		if (![_db open]) {
			NSLog(@"Could not open db.");
			abort();
		}
	}
	return _db;
}

- (NSSet *)stops
{
	if (_stops == nil) {
		NSMutableSet *newStops = [[NSMutableSet alloc] init];
		
		FMResultSet *result = [self.db executeQuery:@"SELECT * FROM BusStop"];
		while ([result next]){
			NSNumber *stopId = [NSNumber numberWithInt:[result intForColumn:@"stopId"]];
			NSString *stopName = [result stringForColumn:@"stopName"];
			NSNumber *stopLat = [NSNumber numberWithDouble:[result doubleForColumn:@"stopLat"]];
			NSNumber *stopLon = [NSNumber numberWithDouble:[result doubleForColumn:@"stopLon"]];
			
			GRTStop *newStop = [[GRTStop alloc] initWithStopId:stopId stopName:stopName stopLat:stopLat stopLon:stopLon];
			
			[newStops addObject:newStop];
		}
		
		_stops = newStops;
	}
	return _stops;
}

#pragma mark - constructor

- (GRTGtfsSystem *)init
{
	self = [super init];
	if (self != nil) {
		self.routes = [[NSCache alloc] init];
		self.trips = [[NSCache alloc] init];
		self.shapes = [[NSCache alloc] init];
		NSAssert([self.db goodConnection], @"Whether the db is having good connection");
	}
	return self;
}

+ (GRTGtfsSystem *)defaultGtfsSystem
{
	static GRTGtfsSystem *system = nil;
	if (system == nil) {
		system = [[GRTGtfsSystem alloc] init];
	}
	return system;
}

#pragma mark - stops

- (NSArray *)stopsAt:(CLLocationCoordinate2D)coordinate
			  inSpan:(MKCoordinateSpan)span
{
	NSNumber *latitudeStart = [NSNumber numberWithDouble:coordinate.latitude - span.latitudeDelta/2.0];
    NSNumber *latitudeStop = [NSNumber numberWithDouble:coordinate.latitude + span.latitudeDelta/2.0];
    NSNumber *longitudeStart = [NSNumber numberWithDouble:coordinate.longitude - span.longitudeDelta/2.0];
    NSNumber *longitudeStop = [NSNumber numberWithDouble:coordinate.longitude + span.longitudeDelta/2.0];
	
	NSSet *busStops = [self.stops filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"stopLat>%@ && stopLat<%@ && stopLon>%@ && stopLon<%@", latitudeStart, latitudeStop, longitudeStart, longitudeStop]];
	
	NSArray *stopArray = [busStops allObjects];
	if([stopArray count] > kMaxStopsLimit){
		NSRange range;
		range.location = 0;
		range.length = kMaxStopsLimit;
		stopArray = [stopArray subarrayWithRange:range];
	}
	
	return stopArray;
}

- (NSArray *) stopsWithNameLike:(NSString *)str
{
	NSArray *components = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSMutableArray *subpredicates = [NSMutableArray array];
	
	for (NSString *component in components) {
		if([component length] == 0) { continue; }
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stopId.description contains[cd] %@ || stopName contains[cd] %@", component, component];
		[subpredicates addObject:predicate];
	}
	
	return [[self.stops filteredSetUsingPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates]] allObjects];
}

//#pragma mark - stopTimes
//
//- (GRTStopTimes *)stopTimesForStop:(GRTStop *)stop date:(NSDate *)date
//{
//	return nil; // TODO
//}

@end
