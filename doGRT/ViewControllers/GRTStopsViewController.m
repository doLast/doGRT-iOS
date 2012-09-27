//
//  GRTStopsViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import "GRTStopsViewController.h"
#import "UINavigationController+Rotation.h"
#import "GRTStopDetailsViewController.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopsViewController ()

@property (nonatomic, strong) id<GRTStopAnnotation> searchedStop;
@property (nonatomic, strong, readonly) NSOperationQueue *mapUpdateQueue;
@property (nonatomic, strong) NSArray *nearbyStops;

@end

@implementation GRTStopsViewController

@synthesize stops = _stops;
@synthesize searchedStop = _searchedStop;
@synthesize mapUpdateQueue = _mapUpdateQueue;
@synthesize nearbyStops = _nearbyStops;

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

- (void)setNearbyStops:(NSArray *)nearbyStops
{
	if (nearbyStops != _nearbyStops) {
		_nearbyStops = nearbyStops;
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:YES];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"doGRT";
	self.nearbyStops = nil;
	
	// Hide SearchBar
	UISearchBar *searchBar = self.searchDisplayController.searchBar;
	[searchBar setFrame:CGRectMake(0, 0 - searchBar.frame.size.height, searchBar.frame.size.width, searchBar.frame.size.height)];
	
	// Center Waterloo on map
	[self setMapView:self.mapView withRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(43.47273, -80.541218), 2000, 2000) animated:NO];
	
	// Enable user location tracking
	[self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self setNavigationBarHidden:self.searchDisplayController.active animated:animated];
	[self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	// Reload favorites
	[self refreshFavoriteStops];
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
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
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
		NSMutableArray *toRemove = [[self.mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTFavoriteStop class]]] mutableCopy];
		NSMutableArray *toAdd = [self.stops mutableCopy];
		[toAdd removeObjectsInArray:toRemove];
		[toRemove removeObjectsInArray:self.stops];
		
		NSLog(@"Adding: %@, Removing: %@", toAdd, toRemove);
		
		[self.mapView removeAnnotations:toRemove];
		[self.mapView addAnnotations:toAdd];
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
		
		// Also remove stops overlay on fav stops
		NSSet *visibleFavAnnotations = [visibleAnnotations filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTFavoriteStop class]]];
		for (GRTFavoriteStop *fav in visibleFavAnnotations) {
			[nonVisibleAnnotations addObject:fav.stop];
		}
		
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

- (void)pushStopDetailsForStop:(GRTStop *)stop
{
	GRTStopTimes *stopTimes = [[GRTStopTimes alloc] initWithStop:stop];
	GRTStopDetailsViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"stopDetailsView"];
	viewController.stopTimes = stopTimes;
	[self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - actions

- (IBAction)showPreferences:(id)sender
{
	// TODO: Display Preferences
	NSLog(@"Showing preferences");
}

- (IBAction)startTrackingUserLocation:(id)sender
{
	[self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (IBAction)didTapLeftNavButton:(id)sender
{
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
		[self showPreferences:sender];
	}
	else {
		[self startTrackingUserLocation:sender];
	}
}

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
		[self setMapView:self.mapView withRegion:MKCoordinateRegionMakeWithDistance(stop.coordinate, 300, 300) animated:NO];
	}
	else {
		[self pushStopDetailsForStop:stop];
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
			[self pushStopDetailsForStop:stop];
		}
	}
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	if (self.isViewLoaded) {
		self.nearbyStops = [[GRTGtfsSystem defaultGtfsSystem] stopsAroundLocation:userLocation.location withinDistance:500];
	}
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//	BOOL locatable = [CLLocationManager locationServicesEnabled];
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0) {
		return @"Nearby Stops";
	}
//	else if (section == 1) {
		return @"Favorites";
//	}
//	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return [self.nearbyStops count];
	}
//	else if (section == 1) {
		return [self.stops count];
//	}
//	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"stopCell";
	
    // Dequeue or create a new cell.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	id<GRTStopAnnotation> stop = nil;
	if (indexPath.section == 0) {
		stop = [self.nearbyStops objectAtIndex:indexPath.row];
	}
	else if (indexPath.section == 1) {
		stop = [self.stops objectAtIndex:indexPath.row];
	}
	
    cell.textLabel.text = stop.title;
	
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", stop.subtitle];
	
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id<GRTStopAnnotation> stop = [self.stops objectAtIndex:indexPath.row];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didSearchedStop:)]) {
		[self.delegate didSearchedStop:stop.stop];
	}
	else {
		[self pushStopDetailsForStop:stop.stop];
	}
}

@end
