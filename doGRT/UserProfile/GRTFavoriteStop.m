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

@dynamic stop_id;
@dynamic display_name;
@dynamic display_order;

- (CLLocationCoordinate2D)coordinate
{
	GRTStop *stop = [[GRTGtfsSystem defaultGtfsSystem] stopById:self.stop_id];
	return stop.coordinate;
}

- (NSString *)title
{
	return self.display_name;
}

- (NSString *)subtitle
{
	return [NSString stringWithFormat:@"%@", self.stop_id];
}

@end
