//
//  GRTBusStopsViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import "GRTStopsViewController.h"
#import "UINavigationController+Rotation.h"
#import "GRTStopTimesViewController.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopsViewController ()

@property (nonatomic, strong) id<GRTStopAnnotation> searchedStop;
@property (nonatomic, strong, readonly) NSOperationQueue *mapUpdateQueue;

@end

@implementation GRTStopsViewController

@synthesize stops = _stops;
@synthesize searchedStop = _searchedStop;
@synthesize mapUpdateQueue = _mapUpdateQueue;

@synthesize tableView = _tableView;
@synthesize mapView = _mapView;
@synthesize searchResultViewController = _searchResultViewController;
@synthesize delegate = _delegate;

- (void)setStops:(NSArray *)stops
{
	if (stops != _stops) {
		_stops = stops;
	}
}

- (NSOperationQueue *)mapUpdateQueue
{
	if (_mapUpdateQueue == nil) {
		_mapUpdateQueue = [[NSOperationQueue alloc] init];
	}
	return _mapUpdateQueue;
}

#pragma mark - view life-cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Hide SearchBar
	UISearchBar *searchBar = self.searchDisplayController.searchBar;
	[searchBar setFrame:CGRectMake(0, 0 - searchBar.frame.size.height, searchBar.frame.size.width, searchBar.frame.size.height)];
	
	// Center Waterloo on map
	[self setMapView:self.mapView withRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(43.47273, -80.541218), 2000, 2000) animated:NO];
	
	// Enable user location tracking
	self.mapView.userTrackingMode = MKUserTrackingModeFollow;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Reload favorites
	[self refreshFavoriteStops];
	
	[self setNavigationBarHidden:self.searchDisplayController.active animated:animated];
	[self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self setNavigationBarHidden:NO animated:animated];
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
			[UIView animateWithDuration:duration animations:^{
				self.mapView.alpha = 1.0;
			} completion:^(BOOL finished){
				[self updateMapView:self.mapView];
//				if (self.mapView.userLocation == nil) {
//					self.mapView.userTrackingMode = MKUserTrackingModeFollow;
//				}
			}];
		}
		else {
			[UIView animateWithDuration:duration animations:^{
				self.mapView.alpha = 0.0;
			} completion:^(BOOL finished){
//				self.mapView.userTrackingMode = MKUserTrackingModeNone;
			}];
		}
	}
}

#pragma mark - view update

- (void)refreshFavoriteStops
{
	self.stops = [[GRTUserProfile defaultUserProfile] allFavoriteStops];
	[self.tableView reloadData];
	
	if (self.mapView != nil) {
		[self.mapView removeAnnotations:self.mapView.annotations];
		[self.mapView addAnnotations:self.stops];
		[self updateMapView:self.mapView];
	}
}

- (void)setMapView:(MKMapView *)mapView withRegion:(MKCoordinateRegion)region animated:(BOOL)animated
{
	if (self.searchedStop != nil) {
		for (id<MKAnnotation> annotationView in mapView.selectedAnnotations) {
			[mapView deselectAnnotation:annotationView animated:NO];
		}
		[self.mapView selectAnnotation:self.searchedStop animated:YES];
	}
	[mapView setRegion:region animated:animated];
}

- (void)updateMapView:(MKMapView *)mapView
{
	// If invisible, do nothing
	if (mapView.alpha == 0) {
		return;
	}
		
	NSOperation *annotationUpdate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performAnnotationUpdateOnMapView:) object:mapView];
	
	[self.mapUpdateQueue waitUntilAllOperationsAreFinished];
	[self.mapUpdateQueue addOperation:annotationUpdate];
}

- (void)performAnnotationUpdateOnMapView:(MKMapView *)mapView
{
	@synchronized(self) {
		MKCoordinateRegion region = mapView.region;
		
		// find out all need to remove annotations
		NSSet *visibleAnnotations = [mapView annotationsInMapRect:[mapView visibleMapRect]];
		NSSet *allAnnotations = [NSSet setWithArray:mapView.annotations];
		NSMutableSet *nonVisibleAnnotations = [NSMutableSet setWithSet:allAnnotations];
		[nonVisibleAnnotations minusSet:visibleAnnotations];
		[nonVisibleAnnotations filterUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTStop class]]];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[mapView removeAnnotations:[nonVisibleAnnotations allObjects]];
			
			// if not too many annotations currently on the map
			if([[mapView annotations] count] < 50){
				// get bus stops in current region
				NSArray *newStops = [[GRTGtfsSystem defaultGtfsSystem] stopsInRegion:region];
				
				NSMutableSet *newAnnotations = [NSMutableSet setWithArray:newStops];
				[newAnnotations minusSet:visibleAnnotations];
				
				[mapView addAnnotations:[newAnnotations allObjects]];
			}
		});
	}
}

- (void)pushStopTimesForStop:(GRTStop *)stop
{
	GRTStopTimes *stopTimes = [[GRTStopTimes alloc] initWithStop:stop];
	GRTStopTimesViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"stopTimesView"];
	viewController.stopTimes = stopTimes;
	[self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - actions

- (IBAction)showSearch:(id)sender
{
	UISearchBar *searchBar = self.searchDisplayController.searchBar;
	// animate in
    [UIView animateWithDuration:0.2 animations:^{
		[searchBar setFrame:CGRectMake(0, 0, searchBar.frame.size.width, searchBar.frame.size.height)];
	} completion:^(BOOL finished) {
		[self.searchDisplayController setActive:YES animated:YES];
		[self.searchDisplayController.searchBar becomeFirstResponder];
	}];
	[self setNavigationBarHidden:YES animated:YES];
}

#pragma mark - search delegate

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[super.navigationController setNavigationBarHidden:hidden animated:animated];
	}
}

//- (UINavigationController *)navigationController
//{
//	// Prevent the search display controller to manipulate the navigation bar
//	return nil;
//}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	[self setNavigationBarHidden:YES animated:YES];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
	UISearchBar *searchBar = self.searchDisplayController.searchBar;
	// animate out
	[UIView animateWithDuration:0.2 animations:^{
		[searchBar setFrame:CGRectMake(0, 0 - searchBar.frame.size.height, searchBar.frame.size.width, searchBar.frame.size.height)];
	} completion:^(BOOL finished){
		
	}];
	[self setNavigationBarHidden:NO animated:YES];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	if (controller.active && [searchString length] > 1) {
		self.searchResultViewController.stops = [[GRTGtfsSystem defaultGtfsSystem] stopsWithNameLike:searchString];
		return YES;
	}
	return NO;
}

#pragma mark - stops search delegate

- (void)didSearchedStop:(GRTStop *)stop
{
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		self.searchedStop = stop;
		[self.searchDisplayController setActive:NO animated:YES];
		[self setMapView:self.mapView withRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake([stop.stopLat doubleValue], [stop.stopLon doubleValue]), 300, 300) animated:NO];
	}
	else {
		[self pushStopTimesForStop:stop];
	}
}

#pragma mark - Map View Delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	[self updateMapView:mapView];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	if (view.annotation == self.searchedStop) {
		self.searchedStop = nil;
	}
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
	
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
	if (self.searchedStop != nil && [mapView.selectedAnnotations count] == 0) {
		[mapView selectAnnotation:self.searchedStop animated:NO];
	}
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	if ([view.annotation respondsToSelector:@selector(stop)]) {
		GRTStop *stop = [((id<GRTStopAnnotation>) view.annotation) stop];
		if (stop != nil) {
			[self pushStopTimesForStop:stop];
		}
	}
}


#pragma mark - Table View Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.stops count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"stopCell";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	id<GRTStopAnnotation> stop = [self.stops objectAtIndex:indexPath.row];
	
    cell.textLabel.text = stop.title;
	
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", stop.subtitle];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id<GRTStopAnnotation> stop = [self.stops objectAtIndex:indexPath.row];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didSearchedStop:)]) {
		[self.delegate didSearchedStop:stop.stop];
	}
	else {
		[self pushStopTimesForStop:stop.stop];
	}
}

@end
