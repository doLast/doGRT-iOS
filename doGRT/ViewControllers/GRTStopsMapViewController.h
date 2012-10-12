//
//  GRTStopsMapViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-10-4.
//
//

#import <MapKit/MapKit.h>
#import "GRTGtfsSystem.h"

@class GRTStopsMapViewController;

@protocol GRTStopsMapViewControllerDelegate <NSObject>

- (void)mapViewController:(GRTStopsMapViewController *)mapViewController wantToPresentStop:(GRTStop *)stop;
- (void)mapViewController:(GRTStopsMapViewController *)mapViewController didUpdateUserLocation:(MKUserLocation *)userLocation;

@end

@interface GRTStopsMapViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet id<GRTStopsMapViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSArray *stops;
@property (nonatomic, strong) GRTShape *shape;
@property (nonatomic) CLLocationDegrees inRegionStopsDisplayThreshold;

- (IBAction)startTrackingUserLocation:(id)sender;
- (void)centerMapToRegion:(MKCoordinateRegion)region animated:(BOOL)animated;
- (void)setMapAlpha:(CGFloat)alpha animationDuration:(NSTimeInterval)duration;
- (void)selectStop:(id<GRTStopAnnotation>)annotation;

@end
