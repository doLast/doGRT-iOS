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
@synthesize willBePresentedStop = _willBePresentedStop;
@synthesize annotationUpdateQueue = _annotationUpdateQueue;

- (void)setStops:(NSArray *)stops
{
	NSMutableArray *toRemove = [[self.mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTFavoriteStop class]]] mutableCopy];
	NSMutableArray *toAdd = [stops mutableCopy];
	[toAdd removeObjectsInArray:toRemove];
	[toRemove removeObjectsInArray:stops];
	
	NSLog(@"Adding: %@, Removing: %@", toAdd, toRemove);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.mapView removeAnnotations:toRemove];
		[self.mapView addAnnotations:toAdd];
		[self updateMapView];
	});
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
		
		// Also remove stops overlay on fav stops
		NSSet *visibleFavAnnotations = [visibleAnnotations filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTFavoriteStop class]]];
		for (GRTFavoriteStop *fav in visibleFavAnnotations) {
			[nonVisibleAnnotations addObject:fav.stop];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.mapView removeAnnotations:[nonVisibleAnnotations allObjects]];
			
			// if not too many annotations currently on the map
			if([[self.mapView annotations] count] < 50){
				// get bus stops in current region
				NSArray *newStops = [[GRTGtfsSystem defaultGtfsSystem] stopsInRegion:region];
				
				NSMutableSet *newAnnotations = [NSMutableSet setWithArray:newStops];
				[newAnnotations minusSet:visibleAnnotations];
				
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
		if ([view.annotation isKindOfClass:[GRTStop class]] && [[GRTUserProfile defaultUserProfile] favoriteStopByStop:(GRTStop *)view.annotation] != nil) {
			[mapView removeAnnotation:view.annotation];
		}
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

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(mapViewController:didUpdateUserLocation:)]) {
		[self.delegate mapViewController:self didUpdateUserLocation:userLocation];
	}
}

@end
