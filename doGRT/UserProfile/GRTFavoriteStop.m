//
//  GRTFavoriteStop.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTFavoriteStop.h"
#import "GRTGtfsSystem+Internal.h"

@implementation GRTFavoriteStop

@dynamic stopId;
@dynamic displayName;
@dynamic displayOrder;

- (CLLocationCoordinate2D)coordinate
{
	GRTStop *stop = [[GRTGtfsSystem defaultGtfsSystem] stopById:self.stopId];
	return stop.coordinate;
}

- (NSString *)title
{
	return self.displayName;
}

- (NSString *)subtitle
{
	return [NSString stringWithFormat:@"%@", self.stopId];
}

@end
