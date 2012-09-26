//
//  GRTUserProfile.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTUserProfile.h"
#import "GRTGtfsSystem+Internal.h"

@interface GRTUserProfile ()

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

@end

@implementation GRTUserProfile

- (GRTUserProfile *)init
{
	self = [super init];
	if (self != nil) {
		self.managedObjectContext = [(id) [[UIApplication sharedApplication] delegate]managedObjectContext];
	}
	return self;
}

+ (GRTUserProfile *)defaultUserProfile
{
	static GRTUserProfile *userProfile = nil;
	if (userProfile == nil) {
		userProfile = [[GRTUserProfile alloc] init];
	}
	return userProfile;
}

- (void)addFavoriteStop:(GRTStop *)stop
{
	GRTFavoriteStop *favoriteStop = [NSEntityDescription insertNewObjectForEntityForName:@"GRTFavoriteStop" inManagedObjectContext:self.managedObjectContext];
	favoriteStop.stop_id = stop.stopId;
	favoriteStop.display_name = stop.stopName;
	favoriteStop.display_order = [NSNumber numberWithInteger:[[self favoriteStops] count]];
	
	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		// Handle error
	}
}

- (NSArray *)favoriteStops
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRTFavoriteStop"];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"display_order"
																   ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	NSError *error;
	NSArray *favoriteStops = [self.managedObjectContext executeFetchRequest:request error:&error];
	if (error != nil) {
		// Handle error
	}
	
	return favoriteStops;
}

@end
