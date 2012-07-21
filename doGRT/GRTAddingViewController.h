//
//  GRTAddingViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@class GRTAddingViewController;

@interface GRTAddingViewController : UIViewController <MKMapViewDelegate, UISearchDisplayDelegate, UITableViewDelegate, UITableViewDataSource>

@property (assign, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (assign, nonatomic) IBOutlet MKMapView *mapView;

// Actions
- (IBAction)save:(UIBarButtonItem *)sender;

@end
