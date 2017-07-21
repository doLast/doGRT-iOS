//
//  GRTGtfsSystem.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTGtfsSystem.h"

#import "FMDB.h"
#import "AFNetworking.h"

static const NSInteger kMaxStopsLimit = 30;
static const NSInteger kBuiltInDataVersion = 20161018;
static const NSInteger kBuiltInDataEndDate = 20161218;

NSString * const GRTGtfsDataVersionKey = @"GRTGtfsDataVersionKey";
NSString * const GRTGtfsDataEndDateKey = @"GRTGtfsDataEndDateKey";
NSString * const GRTGtfsDataReleaseNameKey = @"GRTGtfsDataReleaseNameKey";

NSString * const GRTGtfsDataUpdateCheckNotification = @"GRTGtfsDataUpdateCheckNotification";
NSString * const GRTGtfsDataUpdateInProgressNotification = @"GRTGtfsDataUpdateInProgressNotification";
NSString * const GRTGtfsDataUpdateDidFinishNotification = @"GRTGtfsDataUpdateDidFinishNotification";

NSString * const kGRTGtfsDataUpdateJsonUrl = @"http://dolast.com/dogrt/updates/gtfs.json";

@interface GRTGtfsSystem ()

@property (nonatomic, strong, readonly) FMDatabase *db;
@property (nonatomic, strong) NSDictionary *stops;
@property (nonatomic, strong) NSCache *services;
@property (nonatomic, strong) NSCache *routes;
@property (nonatomic, strong) NSCache *trips;
@property (nonatomic, strong) NSCache *shapes;

@property (nonatomic, copy) NSDictionary *updateInfo;
@property (nonatomic, weak) NSURLSessionDownloadTask *updateTask;
@property (nonatomic, strong) AFURLSessionManager *urlSessionManager;

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
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:kBuiltInDataVersion], GRTGtfsDataVersionKey, [NSNumber numberWithInteger:kBuiltInDataEndDate], GRTGtfsDataEndDateKey, nil]];

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.urlSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
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
    if (![[NSFileManager defaultManager] fileExistsAtPath: [URL path]]) {
        return false;
    }
	
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
	NSURL *localURL = [self dbURL];
	NSNumber *dataVersion = [[NSUserDefaults standardUserDefaults] objectForKey:GRTGtfsDataVersionKey];
	
	if (![fileManager fileExistsAtPath:localURL.path] || dataVersion.integerValue < kBuiltInDataVersion) {
		NSURL *dbURL = [[NSBundle mainBundle] URLForResource:@"GRT_GTFS" withExtension:@"sqlite"];
		NSError *error = nil;
		[fileManager removeItemAtURL:localURL error:nil];
		if (![fileManager copyItemAtURL:dbURL toURL:localURL error:&error]) {
			NSLog(@"Fail to copy db with error %@", error.localizedDescription);
			abort();
		}
		NSLog(@"DB copied from %@ to %@", dbURL, localURL);
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:kBuiltInDataVersion] forKey:GRTGtfsDataVersionKey];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:kBuiltInDataEndDate] forKey:GRTGtfsDataEndDateKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	[self addSkipBackupAttributeToItemAtURL:localURL];
		
	NSAssert([self.db goodConnection], @"Whether the db is having good connection");
	
	// Check launching status
	NSLog(@"GtfsSystem boot with dataVersion: %@",
		  [[NSUserDefaults standardUserDefaults] objectForKey:GRTGtfsDataVersionKey]);
}

- (void)checkForUpdate
{
	if (self.updateTask != nil) {
		return;
	}
	
	// Check Update Json source
	NSURL *url = [NSURL URLWithString:kGRTGtfsDataUpdateJsonUrl];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSLog(@"Checking for update from %@", url);

    NSURLSessionDataTask *checkUpdateTask = [self.urlSessionManager dataTaskWithRequest:urlRequest completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error || !responseObject) {
            NSLog(@"Failed to check update: %@", error);
            return;
        }
        NSDictionary *updateInfo = responseObject;

        NSLog(@"Update Info: %@", updateInfo);
        NSNumber *dataVersion = [[NSUserDefaults standardUserDefaults] objectForKey:GRTGtfsDataVersionKey];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
        NSInteger currentDate = components.year * 10000 + components.month * 100 + components.day;

        NSString *releaseDate = [updateInfo objectForKey:@"releaseDate"];
        NSString *releaseName = [updateInfo objectForKey:@"releaseName"];
        NSString *startDate = [updateInfo objectForKey:@"startDate"];

        NSLog(@"CurrentRelease: %ld StartDate: %ld DataVersion: %ld CurrentDate: %ld", (long)releaseDate.integerValue, (long)startDate.integerValue, (long)dataVersion.integerValue, (long)currentDate);
        if (releaseDate.integerValue > dataVersion.integerValue &&
            currentDate >= startDate.integerValue) {
            self.updateInfo = updateInfo;
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:GRTGtfsDataUpdateCheckNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:releaseDate, GRTGtfsDataVersionKey, releaseName, GRTGtfsDataReleaseNameKey, nil]]];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:GRTGtfsDataUpdateCheckNotification object:self userInfo:[NSDictionary dictionary]]];
        }
    }];
    [checkUpdateTask resume];
}

- (void)startUpdate
{
	if (self.updateTask != nil) {
		return;
	}
	NSURL *localURL = [self dbURL];
	NSURL *remoteURL = [NSURL URLWithString:(id) [self.updateInfo objectForKey:@"url"]];
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:remoteURL];

    self.updateTask = [self.urlSessionManager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {

        NSNumber *p = [NSNumber numberWithDouble:downloadProgress.fractionCompleted];
        [[NSNotificationCenter defaultCenter] postNotificationName:GRTGtfsDataUpdateInProgressNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:p, @"progress", nil]];

    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {

        return [localURL copy];

    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {

        if (error) {
            if (error.code == NSURLErrorCancelled) {
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:GRTGtfsDataUpdateDidFinishNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"cancelled", nil]]];
                return;
            }

            self.updateTask = nil;
            NSLog(@"Fail to download update: %@", error);
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:GRTGtfsDataUpdateDidFinishNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"result", nil]]];
            return;
        }

        NSLog(@"Update downloaded: %@", filePath);
        [self addSkipBackupAttributeToItemAtURL:localURL];

        // Update data version
        [[NSUserDefaults standardUserDefaults] setObject:[self.updateInfo objectForKey:@"releaseDate"] forKey:GRTGtfsDataVersionKey];
        [[NSUserDefaults standardUserDefaults] setObject:[self.updateInfo objectForKey:@"endDate"] forKey:GRTGtfsDataEndDateKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Reset local data
        self.stops = nil;
        [self.services removeAllObjects];
        [self.routes removeAllObjects];
        [self.trips removeAllObjects];
        [self.shapes removeAllObjects];
        [self.db close];

        self.updateTask = nil;
        self.updateInfo = nil;

        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:GRTGtfsDataUpdateDidFinishNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"result", nil]]];
    }];

    NSLog(@"Starting update, local: %@, remote: %@", localURL, remoteURL);
    [self.updateTask resume];
}

- (void)abortUpdate
{
	if (self.updateTask == nil) {
		return;
	}

    [self.updateTask cancel];
    self.updateTask = nil;

	NSLog(@"Update aborted");
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

@end
