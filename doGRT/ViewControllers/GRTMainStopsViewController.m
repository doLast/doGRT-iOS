//
//  GRTMainStopsViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import "GRTMainStopsViewController.h"
#import "GRTStopDetailsViewController.h"
#import "GRTStopsTableViewController.h"
#import "GRTPreferencesViewController.h"
#import "UIViewController+GRTGtfsUpdater.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

#import <QuartzCore/QuartzCore.h>

enum GRTStopsTableSection {
	GRTStopsTableHeaderSection = 0,
	GRTStopsTableFavoritesSection,
	GRTStopsTableNearbySection,
	GRTStopsTableSectionTotal, 
};
static const NSString *GRTStopsTableSectionName[GRTStopsTableSectionTotal] = { @"",  @"Favorites", @"Locating..."};

enum GRTStopsViewQueue {
	GRTStopsViewMapUpdateQueue = -1,
	GRTStopsViewTableUpdateQueue,
	GRTStopsViewQueueTotal,
};

@interface GRTMainStopsViewController ()

@property (nonatomic, strong, readonly) NSArray *tableViewControllers;
@property (nonatomic, strong) NSIndexPath *editingFavIndexPath;

@property (nonatomic, strong, readonly) NSArray *operationQueues;
@property (nonatomic, strong) UIBarButtonItem *locateButton;
@property (nonatomic, strong) UIBarButtonItem *searchButton;
@property (nonatomic, strong) UIBarButtonItem *preferencesButton;

@end

@implementation GRTMainStopsViewController

@synthesize tableViewControllers = _tableViewControllers;
@synthesize editingFavIndexPath = _editingFavIndexPath;

@synthesize operationQueues = _operationQueues;
@synthesize locateButton = _locateButton;
@synthesize searchButton = _searchButton;
@synthesize preferencesButton = _preferencesButton;

@synthesize tableView = _tableView;
@synthesize searchResultViewController = _searchResultViewController;
@synthesize stopsMapViewController = _stopsMapViewController;

- (NSArray *)tableViewControllers
{
	if (_tableViewControllers == nil) {
		int i;
		NSMutableArray *tableViewControllers = [NSMutableArray arrayWithCapacity:GRTStopsTableSectionTotal];
		for (i = GRTStopsTableHeaderSection; i < GRTStopsTableSectionTotal; i++) {
			GRTStopsTableViewController *vc = [[GRTStopsTableViewController alloc] init];
			vc.title = [GRTStopsTableSectionName[i] copy];
			[tableViewControllers addObject:vc];
		}
		_tableViewControllers = tableViewControllers;
	}
	return _tableViewControllers;
}

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
	self.editingFavIndexPath = nil;
	
	UIImage *location = [UIImage imageNamed:@"location"];
	UIButton *locateButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[locateButton setImage:location forState:UIControlStateNormal];
	[locateButton addTarget:self.stopsMapViewController action:@selector(startTrackingUserLocation:) forControlEvents:UIControlEventTouchUpInside];
	locateButton.layer.shadowColor = [UIColor blackColor].CGColor;
	locateButton.layer.shadowOpacity = 0.5;
	locateButton.layer.shadowRadius = 0;
	locateButton.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
	locateButton.frame = CGRectMake(0.0, 0.0, 28.0, 28.0);
	self.locateButton = [[UIBarButtonItem alloc] initWithCustomView:locateButton];
	
	UIImage *search = [UIImage imageNamed:@"magnifier"];
	UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[searchButton addTarget:self action:@selector(showSearch:) forControlEvents:UIControlEventTouchUpInside];
	[searchButton setImage:search forState:UIControlStateNormal];
	searchButton.layer.shadowColor = [UIColor blackColor].CGColor;
	searchButton.layer.shadowOpacity = 0.5;
	searchButton.layer.shadowRadius = 0;
	searchButton.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
	searchButton.frame = CGRectMake(0.0, 0.0, 28.0, 28.0);
	self.searchButton = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
	
	self.preferencesButton = [[UIBarButtonItem alloc] initWithTitle:@"Setting" style:UIBarButtonItemStyleBordered target:self action:@selector(showPreferences:)];
	
	// Hide SearchBar
	UISearchBar *searchBar = self.searchDisplayController.searchBar;
	[searchBar setFrame:CGRectMake(0, 0 - searchBar.frame.size.height, searchBar.frame.size.width, searchBar.frame.size.height)];
	
	// Set search table view controller delegate
	self.searchResultViewController.delegate = self;
	self.stopsMapViewController.delegate = self;
	
	// Center Waterloo on map
	[self.stopsMapViewController centerMapToRegion: MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(43.47273, -80.541218), 2000, 2000) animated:NO];
	
	// Enable user location tracking
	[self.stopsMapViewController performSelector:@selector(startTrackingUserLocation:) withObject:self afterDelay:2];
	
	// Reload favorites
	[self updateFavoriteStops];
	
	// Subscribe to user profile update
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFavoriteStops) name:GRTUserProfileUpdateNotification object:[GRTUserProfile defaultUserProfile]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNearbyStopsDistanceNotification:) name:GRTUserNearbyDistancePreference object:[GRTUserProfile defaultUserProfile]];
	
	// Check for update
	[self becomeGtfsUpdater];
	[self checkForUpdate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	
	[self setNavigationBarHidden:self.searchDisplayController.active animated:animated];
	[self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
	
	// Gtfs update
	[self quitGtfsUpdater];
	[self becomeGtfsUpdater];
	[self updateGtfsUpdaterStatus];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self setNavigationBarHidden:NO animated:animated];
	[self quitGtfsUpdater];
	[super viewDidDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
			self.navigationItem.leftBarButtonItem = self.locateButton;
			self.navigationItem.rightBarButtonItem = self.searchButton;
			[self.stopsMapViewController setMapAlpha:1.0 animationDuration:duration];
		}
		else {
			self.navigationItem.leftBarButtonItem = self.editButtonItem;
			self.navigationItem.rightBarButtonItem = self.preferencesButton;
			[self.stopsMapViewController setMapAlpha:0.0 animationDuration:duration];
		}
	}
	else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationItem.leftBarButtonItem = self.editButtonItem;
		self.navigationItem.rightBarButtonItem = self.preferencesButton;
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
		GRTStopsTableViewController *favTableVC = [self stopsTableViewControllerForSection:GRTStopsTableFavoritesSection];
		NSArray *newStops = [[GRTUserProfile defaultUserProfile] allFavoriteStops];
		if (newStops == favTableVC.stops) {
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			favTableVC.stops = newStops;
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:GRTStopsTableFavoritesSection] withRowAnimation:UITableViewRowAnimationAutomatic];
		});
		
		if (self.stopsMapViewController != nil) {
			self.stopsMapViewController.stops = newStops;
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
		NSNumber *nearbyDistance = [[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserNearbyDistancePreference];
		NSLog(@"Updating nearby stops within %@ meters, center at location: %@", nearbyDistance, location);
		
		GRTStopsTableViewController *nearbyTableVC = [self stopsTableViewControllerForSection:GRTStopsTableNearbySection];
		NSArray *nearbyStops = [[GRTGtfsSystem defaultGtfsSystem] stopsAroundLocation:location withinDistance:nearbyDistance.doubleValue];
		if (nearbyStops == nearbyTableVC.stops) {
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self stopsTableViewControllerForSection:GRTStopsTableNearbySection].title = @"Nearby Stops";
			nearbyTableVC.stops = nearbyStops;
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:GRTStopsTableNearbySection] withRowAnimation:UITableViewRowAnimationAutomatic];
		});
	}
}

- (void)handleNearbyStopsDistanceNotification:(NSNotification *)notification
{
	[self updateNearbyStopsForLocation:self.stopsMapViewController.mapView.userLocation.location];
}

- (void)pushStopDetailsForStop:(GRTStop *)stop
{
	GRTStopTimes *stopTimes = [[GRTStopTimes alloc] initWithStop:stop];
	GRTStopDetailsViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"stopDetailsView"];
	viewController.stopTimes = stopTimes;
	[self.navigationController popToRootViewControllerAnimated:NO];
	[self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - actions

- (IBAction)showPreferences:(id)sender
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[GRTPreferencesViewController showPreferencesInViewController:self];
	}
	else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		[GRTPreferencesViewController showPreferencesFromBarButtonItem:sender];
	}
}

- (IBAction)didTapLeftNavButton:(id)sender
{
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
		[self showPreferences:sender];
	}
	else {
		[self.stopsMapViewController startTrackingUserLocation:sender];
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

- (void)presentStop:(GRTStop *)stop
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		GRTFavoriteStop *favStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:stop];
		[self.stopsMapViewController selectStop: favStop != nil ? favStop : stop];
		
		[self.searchDisplayController setActive:NO animated:YES];
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
		[self pushStopDetailsForStop:stop];
	}
}

- (void)tableViewController:(GRTStopsTableViewController *)tableViewController wantToPresentStop:(GRTStop *)stop
{
	[self presentStop:stop];
}

#pragma mark - stops map delegate

- (void)mapViewController:(GRTStopsMapViewController *)mapViewController wantToPresentStop:(GRTStop *)stop
{
	[self pushStopDetailsForStop:stop];
}

- (void)mapViewController:(GRTStopsMapViewController *)mapViewController didUpdateUserLocation:(MKUserLocation *)userLocation
{
	[self updateNearbyStopsForLocation:userLocation.location];
}

#pragma mark - Table View Data Source

- (GRTStopsTableViewController *)stopsTableViewControllerForSection:(NSInteger)section
{
	return [self.tableViewControllers objectAtIndex:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return GRTStopsTableSectionTotal;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == GRTStopsTableHeaderSection) {
		return nil;
	}
	return [self stopsTableViewControllerForSection:section].title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == GRTStopsTableHeaderSection) {
		return 1;
	}
	return [[self stopsTableViewControllerForSection:section] tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == GRTStopsTableHeaderSection) {
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
	return [[self stopsTableViewControllerForSection:indexPath.section] tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == GRTStopsTableHeaderSection) {
		return [self tableView:tableView didSelectRowAtIndexPath:indexPath];
	}
	[[self stopsTableViewControllerForSection:indexPath.section] tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [[self stopsTableViewControllerForSection:indexPath.section] tableView:tableView canMoveRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	[[self stopsTableViewControllerForSection:sourceIndexPath.section] tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
}

#pragma mark - Table View Delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == GRTStopsTableHeaderSection) {
		return UITableViewCellEditingStyleInsert;
	}
	return [[self stopsTableViewControllerForSection:indexPath.section] tableView:tableView editingStyleForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	id<GRTStopAnnotation> stop = [[self stopsTableViewControllerForSection:indexPath.section].stops objectAtIndex:indexPath.row];
	if (indexPath.section == GRTStopsTableHeaderSection) {
		return [self showSearch:tableView];
	}
	else {
		[self presentStop:stop.stop];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	id<GRTStopAnnotation> stop = [[self stopsTableViewControllerForSection:indexPath.section].stops objectAtIndex:indexPath.row];
	if ([stop isKindOfClass:[GRTFavoriteStop class]]) {
		GRTFavoriteStop *favStop = stop;
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit Favorite Stop Name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		UITextField *textField = [alert textFieldAtIndex:0];
		
		self.editingFavIndexPath = indexPath;
		textField.text = favStop.displayName;
		
		[alert show];
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	return [[self stopsTableViewControllerForSection:sourceIndexPath.section] tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:proposedDestinationIndexPath];
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
		UITextField *textField = [alertView textFieldAtIndex:0];
		if(textField.text.length > 0) {
			GRTFavoriteStop *favStop = [[self stopsTableViewControllerForSection:self.editingFavIndexPath.section].stops objectAtIndex:self.editingFavIndexPath.row];
			BOOL result = [[GRTUserProfile defaultUserProfile] renameFavoriteStop:favStop withName:textField.text];
			if (result) {
				[self.tableView reloadRowsAtIndexPaths:@[self.editingFavIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			}
			self.editingFavIndexPath = nil;
		}
    }
}

@end
