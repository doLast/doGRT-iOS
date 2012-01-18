//
//  GRTMapAnnotation.m
//  doGRT
//
//  Created by Greg Wang on 12-1-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTMapAnnotation.h"

@implementation GRTMapAnnotation

// Center latitude and longitude of the annotion view.
// The implementation of this property must be KVO compliant.
@synthesize coordinate = _coordinate;

// Title and subtitle for use by selection UI.
@synthesize title = _title;
@synthesize subtitle = _subtitle;

- (GRTMapAnnotation *) initAtCoordinate:(CLLocationCoordinate2D)coordinate
							  withTitle:(NSString *)title 
						   withSubtitle:(NSString *)subtitle{
	self = [super init];
	_coordinate = coordinate;
	_title = title;
	_subtitle = subtitle;
	return self;
}


- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate{
	_coordinate = newCoordinate;
}

@end
