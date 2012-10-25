//
//  GRTUserProfile.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTFavoriteStop.h"

@class GRTStop;

extern NSString *GRTUserLaunchCountKey;
extern NSString *GRTUserNearbyDistancePreference;
extern NSString *GRTUserDefaultScheduleViewPreference;
extern NSString *GRTUserProfileUpdateNotification;

@interface GRTUserProfile : NSObject

+ (GRTUserProfile *)defaultUserProfile;

- (void)bootstrap;
- (id)preferenceForKey:(NSString *)key;
- (void)setPreference:(id)value forKey:(NSString *)key;

- (NSArray *)allFavoriteStops;
- (GRTFavoriteStop *)favoriteStopByStop:(GRTStop *)stop;

- (GRTFavoriteStop *)addStop:(GRTStop *)stop;
- (BOOL)removeFavoriteStop:(GRTFavoriteStop *)favoriteStop;
- (BOOL)moveFavoriteStop:(GRTFavoriteStop *)favoriteStop toIndex:(NSUInteger)index;
- (BOOL)renameFavoriteStop:(GRTFavoriteStop *)favoriteStop withName:(NSString *)name;

@end
