//
//  GRTRouteEntry.h
//  doGRT
//
//  Created by Greg Wang on 12-2-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GRTTripEntry : NSObject

@property (retain, nonatomic) NSNumber *tripId;
@property (retain, nonatomic) NSString *tripHeadsign;
@property (retain, nonatomic) NSString *routeId;
@property (retain, nonatomic) NSString *routeLongName;
@property (retain, nonatomic) NSString *routeShortName;

@end
