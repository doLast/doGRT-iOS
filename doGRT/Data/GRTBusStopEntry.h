//
//  GRTBusStopEntry.h
//  doGRT
//
//  Created by Greg Wang on 12-1-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GRTBusStopEntry : NSObject

@property (retain, nonatomic) NSNumber *stopId;
@property (retain, nonatomic) NSString *stopName;
@property (retain, nonatomic) NSNumber *stopLat;
@property (retain, nonatomic) NSNumber *stopLon;

@end
