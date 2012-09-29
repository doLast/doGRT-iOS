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

enum GRTStopsTableSection {
	GRTStopsTableHeaderSection = 0,
	GRTStopsTableNearbySection,
	GRTStopsTableFavoritesSection,
	GRTStopsTableSectionTotal, 
};

enum GRTStopsViewQueue {
	GRTStopsViewMapUpdateQueue = 0,
	GRTStopsViewTableUpdateQueue,
	GRTStopsViewQueueTotal,
};

@interface GRTStopsViewController ()

@property (nonatomic, strong) NSArray *nearbyStops;
@property (nonatomic, strong) id<GRTStopAnnotation> searchedStop;
@property (nonatomic, strong) NSIndexPath *editingFavIndexPath;

@property (nonatomic, strong, readonly) NSArray *operationQueues;
@property (nonatomic, strong) UIBarButtonItem *locateButton;

@end

@implementation GRTStopsViewController

@synthesize stops = _stops;
@synthesize nearbyStops = _nearbyStops;
@synthesize searchedStop = _searchedStop;
@synthesize editingFavIndexPath = _editingFavIndexPath;

@synthesize operationQueues = _operationQueues;
@synthesize locateButton = _locateButton;

@synthesize tableView = _tableView;
@synthesize mapView = _mapView;
@synthesize searchResultViewController = _searchResultViewController;
@synthesize delegate = _delegate;

- (NSArray *)operationQueues
{
	if (_operationQueues == nil) {
		int i;
		NSMutableArray *operationQueues = [NSMutableArray arrayWithCapacity:GRTStopsViewQueueTotal];
		for (i = 0; i < GRTStopsViewQueueTotal; i++) {
			[operationQueues addObject:[[NSOperationQueue alloc] init]];
		}
		_operationQueues = operationQueues;
	}
	return _operationQueues;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
}

#pragma mark - view life-cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"doGRT";
	self.nearbyStops = nil;
	self.searchedStop = nil;
	self.editingFavIndexPath = nil;
	self.locateButton = self.navigationItem.leftBarButtonItem;
	
	// Hide SearchBar
	UISearchBar *searchBar = self.searchDisplayController.searchBar;
	[searchBar setFrame:CGRectMake(0, 0 - searchBar.frame.size.height, searchBar.frame.size.width, searchBar.frame.size.height)];
	
	// Center Waterloo on map
	[self centerMapView:self.mapView toRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(43.47273, -80.541218), 2000, 2000) animated:NO];
	
	// Enable user location tracking
	[self performSelector:@selector(startTrackingUserLocation:) withObject:self afterDelay:2];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	
	[self setNavigationBarHidden:self.searchDisplayController.active animated:animated];
	[self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	// Reload favorites
	[self updateFavoriteStops];
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
			self.navigationItem.leftBarButtonItem = self.locateButton;
			[UIView animateWithDuration:duration animations:^{
				self.mapView.alpha = 1.0;
			} completion:^(BOOL finished){
				[self updateMapView:self.mapView];
			}];
		}
		else {
			self.navigationItem.leftBarButtonItem = self.editButtonItem;
			[UIView animateWithDuration:duration animations:^{
				self.mapView.alpha = 0.0;
			} completion:^(BOOL finished){
				
			}];
		}
	}
}

#pragma mark - view update

- (void)updateFavoriteStops
{
	NSOperation *favUpdate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performFavoriteStopsUpdate) object:nil];
	
	[[self.operationQueues objectAtIndex:GRTStopsViewTableUpdateQueue] addOperation:favUpdate];
}

- (void)performFavoriteStopsUpdate
{
	@synchronized(self.tableView) {
		NSArray *newStops = [[GRTUserProfile defaultUserProfile] allFavoriteStops];
		if (newStops == self.stops) {
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.stops = newStops;
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:GRTStopsTableFavoritesSection] withRowAnimation:UITableViewRowAnimationAutomatic];
		});
		
		if (self.mapView != nil) {
			NSMutableArray *toRemove = [[self.mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTFavoriteStop class]]] mutableCopy];
			NSMutableArray *toAdd = [newStops mutableCopy];
			[toAdd removeObjectsInArray:toRemove];
			[toRemove removeObjectsInArray:newStops];
			
			NSLog(@"Adding: %@, Removing: %@", toAdd, toRemove);
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.mapView removeAnnotations:toRemove];
				[self.mapView addAnnotations:toAdd];
				[self updateMapView:self.mapView];
			});
		}
	}
}

- (void)updateNearbyStopsForLocation:(CLLocation *)location
{
	NSOperation *nearbyUpdate = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performNearbyStopsUpdateWithLocation:) object:location];
	
	[[self.operationQueues objectAtIndex:GRTStopsViewTableUpdateQueue] addOperation:nearbyUpdate];
}

- (void)performNearbyStopsUpdateWithLocation:(CLLocation *)location
{
	@synchronized(self.tableView) {
		NSArray *nearbyStops = [[GRTGtfsSystem defaultGtfsSystem] stopsAroundLocation:location withinDistance:500];
		if (nearbyStops == self.nearbyStops) {
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.nearbyStops = nearbyStops;
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:GRTStopsTableNearbySection] withRowAnimation:UITableViewRowAnimationAutomatic];
		});
	}
}

- (void)centerMapView:(MKMapView *)mapView toRegion:(MKCoordinateRegion)region animated:(BOOL)animated
{
	if (self.searchedStop != nil) {
		for (id<MKAnnotation> annotationView in mapView.selectedAnnotations) {
			[mapView deselectAnnotation:annotationView animated:NO];
		}
		[self.mapView selectAnnotation:self.searchedStop animated:NO];
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
	
	[[self.operationQueues objectAtIndex:GRTStopsViewMapUpdateQueue] addOperation:annotationUpdate];
}

- (void)performAnnotationUpdateOnMapView:(MKMapView *)mapView
{
	@synchronized(mapView) {
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

- (IBAction)didTapRightNavButton:(id)sender
{
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
		[self showPreferences:sender];
	}
	else {
		[self showSearch:sender];
	}
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
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	if (controller.active && [searchString length] > 0) {
		self.searchResultViewController.stops = [[GRTGtfsSystem defaultGtfsSystem] stopsWithNameLike:searchString];
		return YES;
	}
	self.searchResultViewController.stops = nil;
	return NO;
}

#pragma mark - stops search delegate

- (void)didSearchedStop:(GRTStop *)stop
{
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		self.searchedStop = stop;
		GRTFavoriteStop *favStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:self.searchedStop];
		if (favStop != nil) {
			self.searchedStop = favStop;
		}
		[self.searchDisplayController setActive:NO animated:YES];
		[self centerMapView:self.mapView toRegion:MKCoordinateRegionMakeWithDistance(stop.coordinate, 300, 300) animated:NO];
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
		[self updateNearbyStopsForLocation:userLocation.location];
	}
}

#pragma mark - Table View Data Source

- (NSArray *)stopsArrayForSection:(NSInteger)section
{
	if (self.delegate != nil) {
		return self.stops;
	}
	else if (section == GRTStopsTableFavoritesSection) {
		return self.stops;
	}
	else if (section == GRTStopsTableNearbySection){
		return self.nearbyStops;
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (self.delegate != nil) {
		return 1;
	}
	return GRTStopsTableSectionTotal;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (self.delegate != nil) {
		return nil;
	}
	else if (section == GRTStopsTableNearbySection) {
		if (self.nearbyStops == nil) {
			return @"Locating...";
		}
		return @"Nearby Stops";
	}
	else if (section == GRTStopsTableFavoritesSection) {
		return @"Favorites";
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.delegate != nil) {
		return [self.stops count];
	}
	else if (section == GRTStopsTableHeaderSection) {
		return 1;
	}
	return [[self stopsArrayForSection:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.delegate != nil || indexPath.section != GRTStopsTableHeaderSection) {
		static NSString *CellIdentifier = @"stopCell";
		
		// Dequeue or create a new cell.
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		id<GRTStopAnnotation> stop = [[self stopsArrayForSection:indexPath.section] objectAtIndex:indexPath.row];
		
		cell.textLabel.text = stop.title;
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", stop.subtitle];
		if (indexPath.section == GRTStopsTableFavoritesSection) {
			cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		}
		else {
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
		}
		
		return cell;
	}
	else /* if (indexPath.section == GRTStopsTableHeaderSection) */ {
		static NSString *CellIdentifier = @"searchButtonCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			cell.textLabel.text = @"Tap to Search";
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.textLabel.textColor = [UIColor lightGrayColor];
			cell.editing = YES;
		}
		return cell;
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.delegate != nil) {
		return;
	}
	else if (indexPath.section == GRTStopsTableHeaderSection) {
		return [self tableView:tableView didSelectRowAtIndexPath:indexPath];
	}
	
	id<GRTStopAnnotation> stop = [[self stopsArrayForSection:indexPath.section] objectAtIndex:indexPath.row];
	GRTFavoriteStop *favoriteStop = nil;
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		favoriteStop = [[GRTUserProfile defaultUserProfile] addStop:stop.stop];
		if (favoriteStop != nil) {
			[self updateFavoriteStops];
		}
		else {
			// highlight the stop that already in favorites
		}
	}
	else if (editingStyle == UITableViewCellEditingStyleDelete) {
		if ([stop isKindOfClass:[GRTFavoriteStop class]]) {
			favoriteStop = stop;
			if ([[GRTUserProfile defaultUserProfile] removeFavoriteStop:favoriteStop]) {
				[self updateFavoriteStops];
			}
		}
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	BOOL canMove = self.delegate == nil && indexPath.section == GRTStopsTableFavoritesSection;
	return canMove;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	NSArray *stops = [self stopsArrayForSection:sourceIndexPath.section];
	if (stops == nil) {
		return;
	}
	id<GRTStopAnnotation> stop = [stops objectAtIndex:sourceIndexPath.row];
	if (![stop isKindOfClass:[GRTFavoriteStop class]]) {
		return;
	}
	BOOL result = [[GRTUserProfile defaultUserProfile] moveFavoriteStop:stop toIndex:destinationIndexPath.row];
	if (result) {
		// Bugging
		self.stops = [[GRTUserProfile defaultUserProfile] allFavoriteStops];
	}
}

#pragma mark - Table View Delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.delegate != nil) {
		
	}
	else if (indexPath.section == GRTStopsTableHeaderSection) {
		return UITableViewCellEditingStyleInsert;
	}
	else if (indexPath.section == GRTStopsTableNearbySection) {
		return UITableViewCellEditingStyleInsert;
	}
	else if (indexPath.section == GRTStopsTableFavoritesSection) {
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id<GRTStopAnnotation> stop = [[self stopsArrayForSection:indexPath.section] objectAtIndex:indexPath.row];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didSearchedStop:)]) {
		[self.delegate didSearchedStop:stop.stop];
	}
	else if (indexPath.section == GRTStopsTableHeaderSection) {
		return [self showSearch:tableView];
	}
	else {
		[self pushStopDetailsForStop:stop.stop];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (self.delegate == nil && indexPath.section == GRTStopsTableFavoritesSection) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit Favorite Stop Name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		UITextField *textField = [alert textFieldAtIndex:0];
		
		GRTFavoriteStop *stop = [[self stopsArrayForSection:indexPath.section] objectAtIndex:indexPath.row];
		self.editingFavIndexPath = indexPath;
		textField.text = stop.displayName;
		
		[alert show];
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	NSArray *array = [self stopsArrayForSection:sourceIndexPath.section];
	if (proposedDestinationIndexPath.section != sourceIndexPath.section) {
		NSInteger row = (sourceIndexPath.section > proposedDestinationIndexPath.section) ?
		0 : [array count] - 1;
		return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
	}
	else if (proposedDestinationIndexPath.row >= [array count]) {
		return [NSIndexPath indexPathForRow:[array count] - 1 inSection:sourceIndexPath.section];
	}
	
	return proposedDestinationIndexPath;
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
		UITextField *textField = [alertView textFieldAtIndex:0];
		if(textField.text.length > 0) {
			GRTFavoriteStop *favStop = [[self stopsArrayForSection:self.editingFavIndexPath.section] objectAtIndex:self.editingFavIndexPath.row];
			BOOL result = [[GRTUserProfile defaultUserProfile] renameFavoriteStop:favStop withName:textField.text];
			if (result) {
				[self.tableView reloadRowsAtIndexPaths:@[self.editingFavIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			}
		}
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
		[self.tableView reloadData];
    }
}

@end
