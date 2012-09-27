//
//  GRTUserProfile.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTFavoriteStop.h"

@class GRTStop;

@interface GRTUserProfile : NSObject

+ (GRTUserProfile *)defaultUserProfile;

- (NSArray *)allFavoriteStops;
- (GRTFavoriteStop *)favoriteStopByStop:(GRTStop *)stop;

- (GRTFavoriteStop *)addStop:(GRTStop *)stop;
- (BOOL)removeFavoriteStop:(GRTFavoriteStop *)favoriteStop;
- (BOOL)moveFavoriteStop:(GRTFavoriteStop *)favoriteStop toIndex:(NSUInteger)index;

@end
