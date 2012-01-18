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

@protocol GRTAddingViewControllerDelegate
- (void)addingViewControllerDidFinishWithBusStopNumber:(NSNumber *)busStopNumber
									   withBusStopName:(NSString *)busStopName;
@end

@interface GRTAddingViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet id <GRTAddingViewControllerDelegate> delegate;
@property (assign, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (assign, nonatomic) IBOutlet UINavigationItem *navigationBar;
@property (assign, nonatomic) IBOutlet UITextField *busStopNumberText;
@property (assign, nonatomic) IBOutlet MKMapView *mapView;

//@property (assign, nonatomic) MKCoordinateRegion mapRegion;
@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;

// Actions
- (IBAction)valueChanged:(UITextField *)sender;
- (IBAction)cancel:(UIBarButtonItem *)sender;
- (IBAction)save:(UIBarButtonItem *)sender;

@end
