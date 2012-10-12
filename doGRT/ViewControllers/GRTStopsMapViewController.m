//
//  GRTStopsMapViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-10-4.
//
//

#import "GRTStopsMapViewController.h"
#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopsMapViewController ()

@property (nonatomic, weak) id<GRTStopAnnotation> willBePresentedStop;
@property (nonatomic, strong, readonly) NSOperationQueue *annotationUpdateQueue;

@end

@implementation GRTStopsMapViewController

@synthesize delegate = _delegate;
@synthesize mapView = _mapView;
@synthesize stops = _stops;
@synthesize shape = _shape;
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
		
		NSLog(@"Adding: %@, Removing: %@", toAdd, toRemove);
		
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
	if (shape != nil) {
		dispatch_async(dispatch_get_main_queue(), ^{
			_shape = shape;
			[self.mapView addOverlay:_shape.polyline];
		});
	}
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
	// Do any additional setup after loading the view.
	
	// Center Waterloo on map
	[self centerMapToRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(43.47273, -80.541218), 2000, 2000) animated:NO];
	
	self.stops = self.stops;
	self.shape = self.shape;
	
	self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:68.0/255.0 green:140.0/255.0 blue:203.0/255.0 alpha:1.0];
}

#pragma mark - view update

- (void)updateMapView
{
	// If invisible, do nothing
	if (self.mapView.alpha == 0) {
		return;
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
			for (GRTFavoriteStop *fav in self.stops) {
				[newAnnotations removeObject:fav.stop];
			}
			
			// if not too many annotations currently on the map
			if([[self.mapView annotations] count] < 50){
				[self.mapView addAnnotations:[newAnnotations allObjects]];
			}
		});
	}
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
	if (self.willBePresentedStop != nil) {
		for (id<MKAnnotation> annotationView in self.mapView.selectedAnnotations) {
			[self.mapView deselectAnnotation:annotationView animated:NO];
		}
		[self.mapView selectAnnotation:self.willBePresentedStop animated:NO];
	}
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
			else {
				pin.pinColor = MKPinAnnotationColorRed;
			}
			pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		}
//		if ([view.annotation isKindOfClass:[GRTStop class]] && [[GRTUserProfile defaultUserProfile] favoriteStopByStop:(GRTStop *)view.annotation] != nil) {
//			[mapView removeAnnotation:view.annotation];
//		}
	}
	if (self.willBePresentedStop != nil && [mapView.selectedAnnotations count] == 0) {
		[mapView selectAnnotation:self.willBePresentedStop animated:NO];
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
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
	if ([overlay isKindOfClass:[MKPolyline class]]) {
		MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
		polylineView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
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
