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

- (void)addFavoriteStop:(GRTStop *)stop;
- (NSArray *)favoriteStops;

@end
