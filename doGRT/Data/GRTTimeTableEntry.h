//
//  GRTTimeTableEntry.h
//  doGRT
//
//  Created by Greg Wang on 12-1-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GRTTimeTableEntry : NSObject

@property (retain, nonatomic) NSString *routeId;
//@property (retain, nonatomic) NSString *routeLongName;
//@property (retain, nonatomic) NSString *routeShortName;
@property (retain, nonatomic) NSString *tripHeadsign;
@property (retain, nonatomic) NSNumber *arrivalTime;
@property (retain, nonatomic) NSNumber *departureTime;

//- (GRTTimeTableEntry *) initWithRouteId:(NSString *)routeId 
//						   tripHeadsign:(NSString *)tripHeadsign 
//							arrivalTime:(NSNumber *)arrivalTime 
//						  departureTime:(NSNumber *)departureTime;

@end
