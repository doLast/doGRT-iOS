//
//  GRTTimeTableEntry.m
//  doGRT
//
//  Created by Greg Wang on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTStopTime.h"
#import "GRTUserProfile.h"
#import "GRTGtfsSystem+Internal.h"

@interface GRTStopTime ()

@property (nonatomic, strong) NSNumber *tripId;
@property (nonatomic, strong) NSNumber *stopSequence;
@property (nonatomic, strong) NSNumber *stopId;
@property (nonatomic, strong) NSNumber *arrivalTime;
@property (nonatomic, strong) NSNumber *departureTime;

@end

@implementation GRTStopTime

@synthesize tripId = _tripId;
@synthesize stopSequence = _stopSequence;
@synthesize stopId = _stopId;
@synthesize arrivalTime = _arrivalTime;
@synthesize departureTime = _departureTime;

- (GRTTrip *)trip
{
	return [[GRTGtfsSystem defaultGtfsSystem] tripById:self.tripId];
}

- (GRTStop *)stop
{
	return [[GRTGtfsSystem defaultGtfsSystem] stopById:self.stopId];
}

- (CLLocation *)location
{
	return self.stop.location;
}

- (CLLocationCoordinate2D)coordinate
{
	return self.stop.coordinate;
}

- (NSString *)title
{
	return self.stop.stopName;
}

- (NSString *)subtitle
{
	return [NSString stringWithFormat:@"%@ Leave at: %@", self.trip.route.routeId, self.formattedDepartureTime];
}

- (GRTStopTime *)initWithTripId:(NSNumber *)tripId stopSequence:(NSNumber *)stopSequence stopId:(NSNumber *)stopId arrivalTime:(NSNumber *)arrivalTime departureTime:(NSNumber *)departureTime
{
	self = [super init];
	if (self != nil) {
		self.tripId = tripId;
		self.stopSequence = stopSequence;
		self.stopId = stopId;
		self.arrivalTime = arrivalTime;
		self.departureTime = departureTime;
	}
	return self;
}

- (NSString *)formattedDepartureTime
{
    // Calculate date components
    NSInteger time = self.departureTime.integerValue;
    if(time >= 240000){
        time -= 240000;
    }
    else if(time < 0){
        time += 240000;
    }

    NSInteger hour = time / 10000;
    NSInteger minute = (time / 100) % 100;

    // Construct date
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSUIntegerMax fromDate:[NSDate date]];
    [dateComponents setHour:hour];
    [dateComponents setMinute:minute];
    NSDate *departureTimeDate = [calendar dateFromComponents:dateComponents];

    // Construct formatter
    NSNumber *display24Hour = [[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserDisplay24HourPreference];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (display24Hour.boolValue) {
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"HHmm" options:0 locale:nil];
    } else {
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hhmma" options:0 locale:nil];
    }

    return [dateFormatter stringFromDate:departureTimeDate];
}

@end
