//
//  GRTTimeTableEntry.h
//  doGRT
//
//  Created by Greg Wang on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

@class GRTTrip;

@interface GRTStopTime : NSObject

@property (nonatomic, weak, readonly) GRTTrip *trip;
@property (nonatomic, strong, readonly) NSNumber *arrivalTime;
@property (nonatomic, strong, readonly) NSNumber *departureTime;

- (GRTStopTime *)initWithTripId:(NSNumber *)tripId arrivalTime:(NSNumber *)arrivalTime departureTime:(NSNumber *)departureTime;

@end
