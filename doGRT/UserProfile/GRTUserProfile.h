//
//  GRTUserProfile.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTFavoriteStop.h"

@class GRTStop;

extern NSString * const GRTUserLaunchCountKey;
extern NSString * const GRTUserNearbyDistancePreference;
extern NSString * const GRTUserDefaultScheduleViewPreference;
extern NSString * const GRTUserDisplay24HourPreference;
extern NSString * const GRTUserDisplayTerminusStopTimesPreference;

extern NSString * const GRTUserProfileUpdateNotification;

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
