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
#import "InformaticToolbar.h"

#import "GRTStopDetailsManager.h"
#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

#import <QuartzCore/QuartzCore.h>
#import "FontAwesomeKit.h"

enum GRTStopsTableSection {
	GRTStopsTableFavoritesSection = 0,
	GRTStopsTableNearbySection,
	GRTStopsTableSectionTotal, 
};
static const NSString *GRTStopsTableSectionName[GRTStopsTableSectionTotal] = { @"Favorites", @"Locating..."};

enum GRTStopsViewQueue {
	GRTStopsViewMapUpdateQueue = -1,
	GRTStopsViewTableUpdateQueue,
	GRTStopsViewQueueTotal,
};

typedef enum GRTStopsViewType {
	GRTStopsTableView = 0,
	GRTStopsMapView,
	GRTStopsViewTypeTotal,
} GRTStopsViewType;

@interface GRTMainStopsViewController ()

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong, readonly) NSArray *tableViewControllers;

@property (nonatomic, strong, readonly) NSArray *operationQueues;

@property (atomic) GRTStopsViewType currentViewType;
@property (nonatomic, strong) UISegmentedControl *viewsSegmentedControl;
@property (nonatomic, strong) UIBarButtonItem *locateButton;
@property (nonatomic, strong) UIBarButtonItem *preferenceButton;

@end

@implementation GRTMainStopsViewController

@synthesize tableViewControllers = _tableViewControllers;

@synthesize operationQueues = _operationQueues;
@synthesize locateButton = _locateButton;

@synthesize currentViewType = _currentViewType;
@synthesize viewsSegmentedControl = _viewsSegmentedControl;

@synthesize tableView = _tableView;
@synthesize searchResultViewController = _searchResultViewController;
@synthesize stopsMapViewController = _stopsMapViewController;

- (NSArray *)tableViewControllers
{
	if (_tableViewControllers == nil) {
		int i;
		NSMutableArray *tableViewControllers = [NSMutableArray arrayWithCapacity:GRTStopsTableSectionTotal];
		for (i = 0; i < GRTStopsTableSectionTotal; i++) {
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

    // Setup Search
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultViewController];
    self.searchController.searchResultsUpdater = self;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;

	// Construct Segmented Control
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
		self.viewsSegmentedControl == nil) {
		UISegmentedControl *viewsSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Stops List", @"Map"]];
		[viewsSegmentedControl addTarget:self action:@selector(toggleViews:) forControlEvents:UIControlEventValueChanged];
		UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:viewsSegmentedControl];

		ITBarItemSet *barItemSet = [[ITBarItemSet alloc] initWithItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], segmentedControlItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]]];

		[self pushBarItemSet:barItemSet animated:YES];

		self.viewsSegmentedControl = viewsSegmentedControl;
	}

    // Construct Buttons
    self.locateButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.stopsMapViewController.mapView];
    self.preferenceButton = [[UIBarButtonItem alloc] initWithTitle:[FAKFontAwesome cogIconWithSize:20].attributedString.string style:UIBarButtonItemStylePlain target:self action:@selector(showPreferences:)];
    [self.preferenceButton setTitleTextAttributes:@{NSFontAttributeName: [FAKFontAwesome iconFontWithSize:20]} forState:UIControlStateNormal];

	// Set sub view controller delegate
	self.searchResultViewController.delegate = self;
	self.stopsMapViewController.delegate = self;
	
	// Initialize map view display
    [self.stopsMapViewController initializeMapView];

	// Enable user location tracking
	[self.stopsMapViewController performSelector:@selector(startTrackingUserLocation:) withObject:self afterDelay:2];
	
	// Reload favorites
	[self updateFavoriteStops];
    
    // Initialize default view type
    self.navigationItem.leftBarButtonItem = self.preferenceButton;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	} else {
		[self showViewType:GRTStopsTableView animationDuration:0.0f];
	}
	
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

	// Gtfs update
	[self updateGtfsUpdaterStatus];
}

- (void)viewDidUnload
{
	[self quitGtfsUpdater];
	[super viewDidUnload];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
			[self showViewType:GRTStopsTableView animationDuration:duration];
		}
		else {
			[self showViewType:GRTStopsMapView animationDuration:duration];
		}
	}
}

#pragma mark - view update

- (void)showViewType:(GRTStopsViewType)type animationDuration:(NSTimeInterval)duration
{
	if (type == GRTStopsTableView) {
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
		[self.stopsMapViewController setMapAlpha:0.0 animationDuration:duration];
	}
	else if (type == GRTStopsMapView) {
		self.navigationItem.rightBarButtonItem = self.locateButton;
		[self.stopsMapViewController setMapAlpha:1.0 animationDuration:duration];
	}
	self.currentViewType = type;
	self.viewsSegmentedControl.selectedSegmentIndex = type;
}

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
	GRTStopDetails *stopDetails = [[GRTStopDetails alloc] initWithStop:stop];
	GRTStopDetailsManager *stopDetailsManager = [[GRTStopDetailsManager alloc] initWithStopDetails:stopDetails];
	GRTStopDetailsViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"stopDetailsView"];
	viewController.stopDetailsManager = stopDetailsManager;
	[self.navigationController popToRootViewControllerAnimated:NO];
	[self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - actions

- (IBAction)toggleViews:(UISegmentedControl *)sender
{
	NSInteger viewIndex = sender.selectedSegmentIndex;
	[self showViewType:(GRTStopsViewType)viewIndex animationDuration:0.2];
}

- (IBAction)showPreferences:(id)sender
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[GRTPreferencesViewController showPreferencesInViewController:self];
	}
	else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        [GRTPreferencesViewController showPreferencesInViewController:self fromBarButtonItem:sender];
	}
}

#pragma mark - search delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
	if (searchController.active && [searchString length] > 0) {
		self.searchResultViewController.stops = [[GRTGtfsSystem defaultGtfsSystem] stopsWithNameLike:searchString];
        [self.searchResultViewController.tableView reloadData];
    } else {
        self.searchResultViewController.stops = nil;
    }
}

#pragma mark - stops search delegate

- (void)presentStop:(GRTStop *)stop
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || self.currentViewType == GRTStopsMapView) {
		GRTFavoriteStop *favStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:stop];
		[self.stopsMapViewController selectStop: favStop != nil ? favStop : stop];
    }
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || self.currentViewType == GRTStopsTableView) {
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
	return [self stopsTableViewControllerForSection:section].title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self stopsTableViewControllerForSection:section] tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self stopsTableViewControllerForSection:indexPath.section] tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
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
	return [[self stopsTableViewControllerForSection:indexPath.section] tableView:tableView editingStyleForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	id<GRTStopAnnotation> stop = [[self stopsTableViewControllerForSection:indexPath.section].stops objectAtIndex:indexPath.row];
	if (tableView.isEditing && [stop isKindOfClass:[GRTFavoriteStop class]]) {
		GRTFavoriteStop *favStop = (GRTFavoriteStop *) stop;

        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Edit Favorite Stop Name" message:nil preferredStyle:UIAlertControllerStyleAlert];

        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = favStop.displayName;
        }];

        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }];
        [alertController addAction:cancelAction];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            UITextField *nameTextField = alertController.textFields.firstObject;
            BOOL result = [[GRTUserProfile defaultUserProfile] renameFavoriteStop:favStop withName:nameTextField.text];
            if (result) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
            }
        }];
        [alertController addAction:defaultAction];

        [self presentViewController:alertController animated:YES completion:nil];
	} else if (tableView.isEditing) {
		[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	} else {
		[self presentStop:stop.stop];
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	return [[self stopsTableViewControllerForSection:sourceIndexPath.section] tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:proposedDestinationIndexPath];
}

@end
