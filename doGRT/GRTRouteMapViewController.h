//
//  GRTRouteMapViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-4-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class GRTTripEntry;

@interface GRTRouteMapViewController : UIViewController <MKMapViewDelegate>

@property (assign, nonatomic) IBOutlet MKMapView *mapView;
@property (retain, nonatomic) GRTTripEntry *route;

@end
