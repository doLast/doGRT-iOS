//
//  GRTUserProfile.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTUserProfile.h"
#import "GRTGtfsSystem+Internal.h"

NSString *GRTUserLaunchCountKey = @"GRTUserLaunchCountKey";
NSString *GRTUserNearbyDistancePreference = @"GRTUserNearbyDistancePreference";
NSString *GRTUserDefaultScheduleViewPreference = @"GRTUserDefaultScheduleViewPreference";
NSString *GRTUserProfileUpdateNotification = @"GRTUserProfileUpdateNotification";

@interface GRTUserProfile ()

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableArray *favoriteStops;

@end

@implementation GRTUserProfile

@synthesize managedObjectContext = _managedObjectContext;
@synthesize favoriteStops = _favoriteStops;

#pragma mark - constructor

- (GRTUserProfile *)init
{
	self = [super init];
	if (self != nil) {
		self.managedObjectContext = [(id) [[UIApplication sharedApplication] delegate]managedObjectContext];
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:0], GRTUserLaunchCountKey, [NSNumber numberWithDouble:500.0], GRTUserNearbyDistancePreference, [NSNumber numberWithInteger:0], GRTUserDefaultScheduleViewPreference, nil]];
		[self refreshFavoriteStops];
	}
	return self;
}

- (void)bootstrap
{
	NSInteger launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:GRTUserLaunchCountKey];
	launchCount++;
	[[NSUserDefaults standardUserDefaults] setInteger:launchCount forKey:GRTUserLaunchCountKey];
	
	NSLog(@"UserProfile boot with launchCount: %d", launchCount);
}

+ (GRTUserProfile *)defaultUserProfile
{
	@synchronized([UIApplication sharedApplication]) {
		static GRTUserProfile *userProfile = nil;
		if (userProfile == nil) {
			userProfile = [[GRTUserProfile alloc] init];
		}
		return userProfile;
	}
}

#pragma mark - data access

- (NSArray *)allFavoriteStops
{
	@synchronized(self) {
		return self.favoriteStops;
	}
}

- (GRTFavoriteStop *)favoriteStopByStop:(GRTStop *)stop;
{
	@synchronized(self){
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"stopId=%@", stop.stopId];
		NSArray *result = [self.favoriteStops filteredArrayUsingPredicate:pred];
		if([result count] > 0){
			return [result objectAtIndex:0];
		}
		return nil;
	}
}

- (void)refreshFavoriteStops
{
	@synchronized(self) {
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRTFavoriteStop"];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
		[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
		NSError *error = nil;
		NSArray *favoriteStops = [self.managedObjectContext executeFetchRequest:request error:&error];
		if (error != nil) {
			// Handle error
			return;
		}
		
		self.favoriteStops = [favoriteStops mutableCopy];
	}
}

#pragma mark - data manipulation

- (void)postNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GRTUserProfileUpdateNotification object:self];
}

- (void)reassignOrder
{
	@synchronized(self) {
		NSUInteger i = 0;
		for (GRTFavoriteStop *favoriteStop in self.favoriteStops) {
			favoriteStop.displayOrder = [NSNumber numberWithInteger:i];
			i++;
		}
	}
}

- (GRTFavoriteStop *)addStop:(GRTStop *)stop
{
	@synchronized(self) {
		if (stop == nil) {
			return nil;
		}
		GRTFavoriteStop *favoriteStop = [self favoriteStopByStop:stop];
		if (favoriteStop != nil) {
			return nil;
		}
		
		favoriteStop = [NSEntityDescription insertNewObjectForEntityForName:@"GRTFavoriteStop" inManagedObjectContext:self.managedObjectContext];
		favoriteStop.stopId = stop.stopId;
		favoriteStop.displayName = stop.stopName;
		favoriteStop.displayOrder = [NSNumber numberWithInteger:[self.favoriteStops count]];
		
		NSError *error = nil;
		if ([self.managedObjectContext save:&error]) {
			[self refreshFavoriteStops];
			[self postNotification];
			return favoriteStop;
		}
		
		NSLog(@"Failed to add stop: %@", error);
		[self.managedObjectContext rollback];
		
		return nil;
	}
}

- (BOOL)removeFavoriteStop:(GRTFavoriteStop *)favoriteStop
{
	@synchronized(self){
		if ([self.favoriteStops containsObject:favoriteStop]) {
			// Delete the managed object
			[self.favoriteStops removeObjectAtIndex:[favoriteStop.displayOrder integerValue]];
			[self.managedObjectContext deleteObject:favoriteStop];
			
			// Commit the change after reassignOrder
			[self reassignOrder];
			
			NSError *error = nil;
			if ([self.managedObjectContext save:&error]) {
				[self refreshFavoriteStops];
				[self postNotification];
				return YES;
			}
			
			NSLog(@"Failed to reassign order: %@", error);
			[self.managedObjectContext rollback];
			[self refreshFavoriteStops];
		}
		return NO;
	}
}

- (BOOL)moveFavoriteStop:(GRTFavoriteStop *)favoriteStop toIndex:(NSUInteger)index
{
	@synchronized(self){
		if ([self.favoriteStops containsObject:favoriteStop]) {
			[self.favoriteStops removeObjectAtIndex:[favoriteStop.displayOrder integerValue]];
			[self.favoriteStops insertObject:favoriteStop atIndex:index];
			
			// Commit the change after reassignOrder
			[self reassignOrder];
			
			NSError *error = nil;
			if ([self.managedObjectContext save:&error]) {
				[self refreshFavoriteStops];
				return YES;
			}
			
			NSLog(@"Failed to reassign order: %@", error);
			[self.managedObjectContext rollback];
			[self refreshFavoriteStops];
		}
		return NO;
	}
}

- (BOOL)renameFavoriteStop:(GRTFavoriteStop *)favoriteStop withName:(NSString *)name
{
	@synchronized(self) {
		if ([self.favoriteStops containsObject:favoriteStop]) {
			favoriteStop.displayName = name;
			
			NSError *error = nil;
			if ([self.managedObjectContext save:&error]) {
				[self refreshFavoriteStops];
				[self postNotification];
				return YES;
			}
			
			NSLog(@"Failed to rename stop: %@", error);
			[self.managedObjectContext rollback];
			[self refreshFavoriteStops];
		}
		return NO;
	}
}

@end
