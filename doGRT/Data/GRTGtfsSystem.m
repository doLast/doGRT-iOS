//
//  GRTGtfsSystem.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTGtfsSystem.h"

#import "FMDatabase.h"
#import "ASIHTTPRequest.h"

static const int kMaxStopsLimit = 30;
NSString * const GRTGtfsDataVersionKey = @"GRTGtfsDataVersionKey";
NSString * const GRTGtfsDataUpdateAvailableNotification = @"GRTGtfsDataUpdateAvailableNotification";
NSString * const GRTGtfsDataUpdateInProgressNotification = @"GRTGtfsDataUpdateInProgressNotification";
NSString * const GRTGtfsDataUpdateDidFinishNotification = @"GRTGtfsDataUpdateDidFinishNotification";

@interface GRTGtfsSystem ()

@property (nonatomic, strong, readonly) FMDatabase *db;
@property (nonatomic, strong) NSDictionary *stops;
@property (nonatomic, strong) NSCache *services;
@property (nonatomic, strong) NSCache *routes;
@property (nonatomic, strong) NSCache *trips;
@property (nonatomic, strong) NSCache *shapes;

@property (nonatomic, copy) NSDictionary *updateInfo;
@property (nonatomic, weak) ASIHTTPRequest *updateRequest;

@end

@implementation GRTGtfsSystem

#pragma mark - getter & setter
@synthesize db = _db;
@synthesize stops = _stops;
@synthesize routes = _routes;
@synthesize trips = _trips;
@synthesize shapes = _shapes;

@synthesize updateInfo = _updateInfo;

- (NSURL *)dbURL
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *libraryDirectory = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
	NSURL *libraryDb = [libraryDirectory URLByAppendingPathComponent:@"GRT_GTFS.sqlite" isDirectory:NO];
	return libraryDb;
}

- (FMDatabase *)db
{
	if (_db == nil) {
		NSURL *dbURL = [self dbURL];
		
		_db = [FMDatabase databaseWithPath:dbURL.path];
	}
	if (![_db goodConnection]) {
		if (![_db open]) {
			NSLog(@"Could not open db.");
		}
	}
	return _db;
}

- (NSDictionary *)stops
{
	if (_stops == nil) {
		NSMutableDictionary *newStops = [[NSMutableDictionary alloc] init];
		
		FMResultSet *result = [self.db executeQuery:@"SELECT * FROM stops"];
		while ([result next]){
			NSNumber *stopId = [NSNumber numberWithInt:[result intForColumn:@"stop_id"]];
			NSString *stopName = [result stringForColumn:@"stop_name"];
			NSNumber *stopLat = [NSNumber numberWithDouble:[result doubleForColumn:@"stop_lat"]];
			NSNumber *stopLon = [NSNumber numberWithDouble:[result doubleForColumn:@"stop_lon"]];
			
			GRTStop *newStop = [[GRTStop alloc] initWithStopId:stopId stopName:stopName stopLat:stopLat stopLon:stopLon];
			
			[newStops setObject:newStop forKey:newStop.stopId];
		}
		
		[result close];
		_stops = newStops;
	}
	return _stops;
}

#pragma mark - initialization

- (GRTGtfsSystem *)init
{
	self = [super init];
	if (self != nil) {
		self.routes = [[NSCache alloc] init];
		self.trips = [[NSCache alloc] init];
		self.shapes = [[NSCache alloc] init];
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:20121223], GRTGtfsDataVersionKey, nil]];
	}
	return self;
}

+ (GRTGtfsSystem *)defaultGtfsSystem
{
	@synchronized([UIApplication sharedApplication]) {
		static GRTGtfsSystem *system = nil;
		if (system == nil) {
			system = [[GRTGtfsSystem alloc] init];
		}
		return system;
	}
}

#pragma mark - data preparation and update

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
	
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

- (void)bootstrap
{
	// Copy database to documents directory if does not exists
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *libraryURL = [self dbURL];
	
	if (![fileManager fileExistsAtPath:libraryURL.path]) {
		NSURL *dbURL = [[NSBundle mainBundle] URLForResource:@"GRT_GTFS" withExtension:@"sqlite"];
		NSError *error = nil;
		if (![fileManager copyItemAtURL:dbURL toURL:libraryURL error:&error]) {
			NSLog(@"Fail to copy db with error %@", error.localizedDescription);
			abort();
		}
		NSLog(@"db copied");
		[self addSkipBackupAttributeToItemAtURL:libraryURL];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:20121223] forKey:GRTGtfsDataVersionKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	NSAssert([self.db goodConnection], @"Whether the db is having good connection");
	
	// Check launching status
	NSLog(@"GtfsSystem boot with dataVersion: %@",
		  [[NSUserDefaults standardUserDefaults] objectForKey:GRTGtfsDataVersionKey]);
}

- (void)checkForUpdate
{
	if (self.updateRequest != nil) {
		return;
	}
	
	// Whether need to update
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
	NSInteger curDate = comps.year * 10000 + comps.month * 100 + comps.day;
	NSNumber *dataVersion = [[NSUserDefaults standardUserDefaults] objectForKey:GRTGtfsDataVersionKey];
	NSLog(@"Current date: %d, dataVersion: %@", curDate, dataVersion);
	
	if (curDate < dataVersion.integerValue) {
		return;
	}
	
	// Check github data referencing
	NSURL *url = [NSURL URLWithString:@"https://github.com/downloads/doLast/doGRT/grt_gtfs.json"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(didFinishCheckingUpdate:)];
	[request startAsynchronous];
	
	return;
}

- (void)startUpdate
{
	NSURL *localURL = [self dbURL];
	NSURL *remoteURL = [NSURL URLWithString:(id) [self.updateInfo objectForKey:@"url"]];
	NSLog(@"Starting update, local: %@, remote: %@", localURL, remoteURL);
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:remoteURL];
	if (self.updateRequest != nil) {
		return;
	}
	self.updateRequest = request;
	
	[request setDownloadDestinationPath:[localURL.path copy]];
	localURL = [localURL URLByAppendingPathExtension:@"download"];
	[request setTemporaryFileDownloadPath:[localURL.path copy]];
	[request setAllowResumeForFileDownloads:YES];
	
	[request setDownloadProgressDelegate:self];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(didFinishDownloadUpdate:)];
	[request setDidFailSelector:@selector(didFailDownloadUpdate:)];
	
	[request startAsynchronous];
}

- (void)abortUpdate
{
	ASIHTTPRequest *request = self.updateRequest;
	self.updateRequest = nil;
	[request clearDelegatesAndCancel];
	NSURL *localURL = [self dbURL];
	localURL = [localURL URLByAppendingPathExtension:@"download"];
	[[NSFileManager defaultManager] removeItemAtURL:localURL error:nil];
	NSLog(@"Update abort, local deleted %@", localURL);
}

#pragma mark - ASI HTTP Request delegate

- (void)didFinishCheckingUpdate:(ASIHTTPRequest *)request
{
	NSData *response = [request responseData];
	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
	if (json == nil) {
		return;
	}
	
	NSLog(@"Update Info: %@", json);
	NSNumber *dataVersion = [[NSUserDefaults standardUserDefaults] objectForKey:GRTGtfsDataVersionKey];
	NSNumber *endDate = [json objectForKey:@"endDate"];
	if (endDate.integerValue > dataVersion.integerValue) {
		self.updateInfo = json;
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:GRTGtfsDataUpdateAvailableNotification object:self]];
	}
}

- (void)didFinishDownloadUpdate:(ASIHTTPRequest *)request
{
	NSURL *localURL = [NSURL URLWithString:request.downloadDestinationPath];
	[self addSkipBackupAttributeToItemAtURL:localURL];
	
	// Update data version
	[[NSUserDefaults standardUserDefaults] setObject:[self.updateInfo objectForKey:@"endDate"] forKey:GRTGtfsDataVersionKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.stops = nil;
	[self.services removeAllObjects];
	[self.routes removeAllObjects];
	[self.trips removeAllObjects];
	[self.shapes removeAllObjects];
	[self.db close];
	
	self.updateRequest = nil;
	self.updateInfo = nil;
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:GRTGtfsDataUpdateDidFinishNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"result", nil]]];
}

- (void)didFailDownloadUpdate:(ASIHTTPRequest *)request
{
	self.updateRequest = nil;
	NSURL *tempURL = [NSURL URLWithString:request.temporaryFileDownloadPath];
	[self addSkipBackupAttributeToItemAtURL:tempURL];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:GRTGtfsDataUpdateDidFinishNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"result", nil]]];
}

- (void)setProgress:(float)progress
{
	NSNumber *p = [NSNumber numberWithFloat:progress];
	[[NSNotificationCenter defaultCenter] postNotificationName:GRTGtfsDataUpdateInProgressNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:p, @"progress", nil]];
}

#pragma mark - data access

- (NSArray *)stopsInRegion:(MKCoordinateRegion)region;
{
	CLLocationCoordinate2D coordinate = region.center;
	MKCoordinateSpan span = region.span;
	
	NSNumber *latitudeStart = [NSNumber numberWithDouble:coordinate.latitude - span.latitudeDelta/2.0];
    NSNumber *latitudeStop = [NSNumber numberWithDouble:coordinate.latitude + span.latitudeDelta/2.0];
    NSNumber *longitudeStart = [NSNumber numberWithDouble:coordinate.longitude - span.longitudeDelta/2.0];
    NSNumber *longitudeStop = [NSNumber numberWithDouble:coordinate.longitude + span.longitudeDelta/2.0];
	
	NSArray *busStops = [[self.stops allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"stopLat>%@ && stopLat<%@ && stopLon>%@ && stopLon<%@", latitudeStart, latitudeStop, longitudeStart, longitudeStop]];
	
	if([busStops count] > kMaxStopsLimit){
		NSRange range;
		range.location = 0;
		range.length = kMaxStopsLimit;
		busStops = [busStops subarrayWithRange:range];
	}
	
	return busStops;
}

- (NSArray *)stopsAroundLocation:(CLLocation *)location withinDistance:(CLLocationDistance)distance;
{
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, distance, distance);
	NSArray *candidates = [self stopsInRegion:region];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2){
		CLLocationDistance d1 = [location distanceFromLocation:obj1];
		CLLocationDistance d2 = [location distanceFromLocation:obj2];
		if (d1 < d2) {
			return NSOrderedAscending;
		}
		else if (d1 > d2) {
			return NSOrderedDescending;
		}
		return NSOrderedSame;
	}];
	NSArray *locations = [candidates sortedArrayUsingDescriptors:@[sortDescriptor]];
	return locations;
}

- (NSArray *)stopsWithNameLike:(NSString *)str
{
	NSArray *components = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSMutableArray *subpredicates = [NSMutableArray array];
	
	for (NSString *component in components) {
		if([component length] == 0) { continue; }
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stopId.description contains[cd] %@ || stopName contains[cd] %@", component, component];
		[subpredicates addObject:predicate];
	}
	
	return [[self.stops allValues] filteredArrayUsingPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates]];
}

- (NSArray *)stopTimesForTrip:(GRTTrip *)trip
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:trip.tripId];
	NSString *query = [NSString stringWithFormat:@"SELECT S.* \
					   FROM stop_times as S \
					   WHERE S.trip_id=? "];
	
	// execute database query
	FMDatabase *db = self.db;
	FMResultSet *result = [db executeQuery:query withArgumentsInArray:arguments];
	if (result == nil){
		NSLog(@"%@", [db lastErrorMessage]);
		abort();
	}
	
	// process the data
	NSMutableArray *stopTimes = [[NSMutableArray alloc] init];
	while ([result next]) {
		//retrieve values for each record
		NSNumber *tripId = [NSNumber numberWithInt:[result intForColumn:@"trip_id"]];
		NSNumber *stopSequence = [NSNumber numberWithInt:[result intForColumn:@"stop_sequence"]];
		NSNumber *stopId = [NSNumber numberWithInt:[result intForColumn:@"stop_id"]];
		NSInteger arrivalInt = [result intForColumn:@"arrival_time"];
		NSInteger departureInt = [result intForColumn:@"departure_time"];
		
		NSNumber *arrivalTime = [NSNumber numberWithInt:arrivalInt];
		NSNumber *departureTime = [NSNumber numberWithInt:departureInt];
		
		GRTStopTime *stopTime = [[GRTStopTime alloc] initWithTripId:tripId stopSequence:stopSequence stopId:stopId arrivalTime:arrivalTime departureTime:departureTime];
		[stopTimes addObject:stopTime];
	}
	
	NSLog(@"Obtain %d stopTimes", [stopTimes count]);
	
	[result close];
	
	return stopTimes;
}

@end
