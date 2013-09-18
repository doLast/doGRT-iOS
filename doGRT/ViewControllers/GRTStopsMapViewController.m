//
//  GRTStopsMapViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-10-4.
//
//

#import "GRTStopsMapViewController.h"
#import "GRTStopDetailsViewController.h"

#import "GRTStopDetailsManager.h"
#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

#import <QuartzCore/QuartzCore.h>

@interface GRTStopsMapViewController ()

@property (atomic, weak) id<GRTStopAnnotation> willBePresentedStop;
@property (nonatomic, strong, readonly) NSOperationQueue *annotationUpdateQueue;

@end

@implementation GRTStopsMapViewController

@synthesize delegate = _delegate;
@synthesize mapView = _mapView;
@synthesize stops = _stops;
@synthesize shape = _shape;
@synthesize inRegionStopsDisplayThreshold = _inRegionStopsDisplayThreshold;
@synthesize willBePresentedStop = _willBePresentedStop;
@synthesize annotationUpdateQueue = _annotationUpdateQueue;

- (void)setStops:(NSArray *)stops
{
	NSMutableArray *toRemove = [NSMutableArray arrayWithArray:_stops];
	NSMutableArray *toAdd = [NSMutableArray arrayWithArray:stops];
	_stops = [stops copy];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		for (id<GRTStopAnnotation> stop in _stops) {
			[toRemove addObject:stop.stop];
		}

		[self.mapView removeAnnotations:toRemove];
		[self.mapView addAnnotations:toAdd];
		[self updateMapView];
	});
}

- (void)setShape:(GRTShape *)shape
{
	if (_shape != nil) {
		[self.mapView removeOverlay:_shape.polyline];
	}
	_shape = shape;
	if (shape != nil) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.mapView addOverlay:_shape.polyline];
		});
	}
}

- (void)setInRegionStopsDisplayThreshold:(CLLocationDegrees)inRegionStopsDisplayThreshold
{
	_inRegionStopsDisplayThreshold = inRegionStopsDisplayThreshold;
	[self updateMapView];
}

- (NSOperationQueue *)annotationUpdateQueue
{
	if (_annotationUpdateQueue == nil) {
		_annotationUpdateQueue = [[NSOperationQueue alloc] init];
	}
	return _annotationUpdateQueue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Center will be presented stop on map
	if (self.willBePresentedStop != nil) {
		CLLocationCoordinate2D coord = self.willBePresentedStop.location.coordinate;
		[self centerMapToRegion:MKCoordinateRegionMakeWithDistance(coord, 2000, 2000) animated:NO];
	} else if ([[self.mapView selectedAnnotations] count] == 0) {
		[self centerMapToRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(43.47273, -80.541218), 2000, 2000) animated:NO];
	}

	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - view update

- (void)updateMapView
{
	// If invisible, do nothing
	if (self.mapView.alpha == 0) {
		return;
	}
	
	MKCoordinateRegion region = self.mapView.region;
	
	if (self.inRegionStopsDisplayThreshold != 0) {
		CLLocationDegrees deltaSum =  region.span.latitudeDelta + region.span.longitudeDelta;
		if (self.inRegionStopsDisplayThreshold < deltaSum) {
			NSMutableArray *visibleAnnotations = [[[self.mapView annotationsInMapRect:[self.mapView visibleMapRect]] allObjects] mutableCopy];
			[visibleAnnotations filterUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTStop class]]];
			[self.mapView removeAnnotations:visibleAnnotations];
			return;
		}
	}
	
	NSOperation *annotationUpdate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performAnnotationUpdate) object:nil];
	
	[self.annotationUpdateQueue addOperation:annotationUpdate];
}

- (void)performAnnotationUpdate
{
	@synchronized(self.mapView) {
		MKCoordinateRegion region = self.mapView.region;
		
		// find out all need to remove annotations
		NSSet *visibleAnnotations = [self.mapView annotationsInMapRect:[self.mapView visibleMapRect]];
		NSSet *allAnnotations = [NSSet setWithArray:self.mapView.annotations];
		NSMutableSet *nonVisibleAnnotations = [NSMutableSet setWithSet:allAnnotations];
		[nonVisibleAnnotations minusSet:visibleAnnotations];
		[nonVisibleAnnotations filterUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTStop class]]];
		
		// get bus stops in current region
		NSArray *newStops = [[GRTGtfsSystem defaultGtfsSystem] stopsInRegion:region];
		NSMutableSet *newAnnotations = [NSMutableSet setWithArray:newStops];
		[newAnnotations minusSet:visibleAnnotations];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.mapView removeAnnotations:[nonVisibleAnnotations allObjects]];
			
			// Prevent adding stops which are overlaying on fav stops
			for (id<GRTStopAnnotation> stop in self.stops) {
				[newAnnotations removeObject:stop.stop];
			}
			
			// if not too many annotations currently on the map
			if([[self.mapView annotationsInMapRect:[self.mapView visibleMapRect]] count] < 50){
				[self.mapView addAnnotations:[newAnnotations allObjects]];
			}
		});
	}
}

- (void)selectSingleAnnotation:(id<MKAnnotation>)annotation
{
	for (id<MKAnnotation> annotationView in self.mapView.selectedAnnotations) {
		[self.mapView deselectAnnotation:annotationView animated:NO];
	}
	[self.mapView selectAnnotation:self.willBePresentedStop animated:YES];
}

#pragma mark - actions

- (IBAction)startTrackingUserLocation:(id)sender
{
	[self setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)setUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
	[self.mapView setUserTrackingMode:mode animated:animated];
}

- (void)centerMapToRegion:(MKCoordinateRegion)region animated:(BOOL)animated
{
	[self.mapView setRegion:region animated:animated];
}

- (void)setMapAlpha:(CGFloat)alpha animationDuration:(NSTimeInterval)duration
{
	[UIView animateWithDuration:duration animations:^{
		self.mapView.alpha = alpha;
	} completion:^(BOOL finished){
		if (alpha > 0) {
			[self updateMapView];
		}
	}];
}

- (void)selectStop:(id<GRTStopAnnotation>)annotation
{
	self.willBePresentedStop = annotation;
	CLLocationDistance distance = self.mapView.frame.size.width;
	BOOL animated = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
	[self centerMapToRegion:MKCoordinateRegionMakeWithDistance(annotation.coordinate, distance, distance) animated:animated];
}

#pragma mark - Map View Delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	if (self.willBePresentedStop != nil && [mapView.annotations containsObject:self.willBePresentedStop]) {
		[self selectSingleAnnotation:self.willBePresentedStop];
	}

	[self updateMapView];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	if (view.annotation == self.willBePresentedStop) {
		self.willBePresentedStop = nil;
	}
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
	for (MKAnnotationView *view in views) {
		if ([view isKindOfClass:[MKPinAnnotationView class]]) {
			MKPinAnnotationView *pin = (MKPinAnnotationView *) view;
			if ([view.annotation isKindOfClass:[GRTFavoriteStop class]]) {
				pin.pinColor = MKPinAnnotationColorGreen;
			}
			else if ([view.annotation isKindOfClass:[GRTStopTime class]]) {
				pin.pinColor = MKPinAnnotationColorPurple;
			}
			else {
				pin.pinColor = MKPinAnnotationColorRed;
			}
			pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		}
	}
	if (self.willBePresentedStop != nil) {
		[self selectSingleAnnotation:self.willBePresentedStop];
	}
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	if (self.delegate != nil && [view.annotation respondsToSelector:@selector(stop)]) {
		GRTStop *stop = [((id<GRTStopAnnotation>) view.annotation) stop];
		if (stop != nil && [self.delegate respondsToSelector:@selector(mapViewController:wantToPresentStop:)]) {
			[self.delegate mapViewController:self wantToPresentStop:stop];
		}
	}
	else {
		GRTStop *stop = [((id<GRTStopAnnotation>) view.annotation) stop];
		GRTStopDetails *stopDetails = [[GRTStopDetails alloc] initWithStop:stop];
		GRTStopDetailsManager *stopDetailsManager = [[GRTStopDetailsManager alloc] initWithStopDetails:stopDetails];
		GRTStopDetailsViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"stopDetailsView"];
		viewController.stopDetailsManager = stopDetailsManager;
		[self.navigationController pushViewController:viewController animated:YES];
	}
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
	if ([overlay isKindOfClass:[MKPolyline class]]) {
		MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
		polylineView.strokeColor = [UIColor colorWithRed:68.0/255.0 green:140.0/255.0 blue:203.0/255.0 alpha:0.8];
		polylineView.lineWidth = 8;
		return polylineView;
	}
	return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mapViewController:didUpdateUserLocation:)]) {
		[self.delegate mapViewController:self didUpdateUserLocation:userLocation];
	}
}

@end
