//
//  Route.h
//  doGRT
//
//  Created by Greg Wang on 12-1-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Route : NSManagedObject

@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * routeLongName;
@property (nonatomic, retain) NSString * routeShortName;

@end
