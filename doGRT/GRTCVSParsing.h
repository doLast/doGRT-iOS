//
//  GRTCVSParsing.h
//  doGRT
//
//  Created by Greg Wang on 12-1-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GRTCVSParsing : NSObject

@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;

- (BOOL) parseCalendar;
- (BOOL) parseRoutes;
- (BOOL) parseStopTimes;
- (BOOL) parseStops;
- (BOOL) parseTrips;
- (BOOL) parseAll;

@end
