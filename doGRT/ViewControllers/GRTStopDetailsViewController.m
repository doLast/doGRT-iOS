//
//  GRTStopDetailsViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

#import "GRTStopDetailsViewController.h"
#import "InformaticToolbar.h"
#import "GRTDetailedTitleButtonView.h"
#import "GRTStopDetailsManager.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

typedef enum GRTStopDetailsViewType {
	GRTStopDetailsViewTypeMixed = 0,
	GRTStopDetailsViewTypeRoutes,
	GRTStopDetailsViewTypeTotal
} GRTStopDetailsViewType;

@interface GRTStopDetailsViewController ()

@property (nonatomic, strong) GRTFavoriteStop *favoriteStop;
@property (nonatomic) GRTStopDetailsViewType viewType;

@end

@implementation GRTStopDetailsViewController

- (void)setFavoriteStop:(GRTFavoriteStop *)favoriteStop
{
	_favoriteStop = favoriteStop;
	if (_favoriteStop != nil) {
		self.favButton.title = @"★";
	}
	else {
		self.favButton.title = @"☆";
	}
}

- (void)setStopTimes:(NSArray *)stopTimes splitLeftAndComingBuses:(BOOL)split
{
	[self.stopTimesViewController setStopTimes:stopTimes splitLeftAndComingBuses:split];
}

- (void)setViewType:(GRTStopDetailsViewType)viewType
{
	if (viewType != _viewType) {
		[UIView animateWithDuration:0.2 animations:^(){
			self.stopTimesViewController.tableView.alpha =
			viewType == GRTStopDetailsViewTypeMixed ? 1.0f : 0.0f;
		}];
	}
	[self.viewsSegmentedControl setSelectedSegmentIndex:viewType];
	_viewType = viewType;
}

#pragma mark - view life-cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Prepare data for views construction
	NSAssert(self.stopDetailsManager != nil, @"Must have a stopTimes");

	// Setup view controllers
	self.favoriteStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:self.stopDetailsManager.stopDetails.stop];
	self.view.backgroundColor = [UIColor underPageBackgroundColor];
	self.stopRoutesViewController.routes = [self.stopDetailsManager.stopDetails routes];

	// Construct Segmented Control
	if (self.viewsSegmentedControl == nil) {
		UISegmentedControl *viewsSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Mixed Schedule", @"Routes List"]];
		viewsSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		[viewsSegmentedControl addTarget:self action:@selector(toggleViews:) forControlEvents:UIControlEventValueChanged];
		UIBarButtonItem *segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:viewsSegmentedControl];
		
		ITBarItemSet *barItemSet = [[ITBarItemSet alloc] initWithItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], segmentedControlItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]]];
		
		[self pushBarItemSet:barItemSet animated:YES];
		
		self.viewsSegmentedControl = viewsSegmentedControl;
	}
	
	NSNumber *index = [[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserDefaultScheduleViewPreference];
	self.viewType = index.integerValue;

	// Config navigation bar
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	
	// Let stop details manager setup the data
	self.stopDetailsManager.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self updateToolbarToLatestStateAnimated:animated];
	// TODO: fix scroll to coming bus index
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.navigationController setToolbarHidden:YES animated:YES];
}

#pragma mark - actions

- (IBAction)toggleViews:(UISegmentedControl *)sender
{
	self.viewType = sender.selectedSegmentIndex;
}

- (IBAction)toggleStopFavorite:(id)sender
{
	if (self.favoriteStop != nil){
		if ([[GRTUserProfile defaultUserProfile] removeFavoriteStop:self.favoriteStop]) {
			self.favoriteStop = nil;
		}
	}
	else {
		self.favoriteStop = [[GRTUserProfile defaultUserProfile] addStop:self.stopDetailsManager.stopDetails.stop];
	}
}

#pragma mark - stop times view controller delegate

- (void)stopTimesViewController:(GRTStopTimesViewController *)stopTimesViewController didSelectStopTime:(GRTStopTime *)stopTime
{
	GRTStopsMapViewController *tripDetailsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"tripDetailsView"];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[stopTimesViewController pushTripDetailsView:tripDetailsVC
										 forStopTime:stopTime
							  toNavigationController:self.navigationController];
	}
	else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *detailNav = (id)[self.splitViewController.viewControllers objectAtIndex:1];
		[detailNav popToRootViewControllerAnimated:NO];
		[stopTimesViewController pushTripDetailsView:tripDetailsVC
										 forStopTime:stopTime
							  toNavigationController:detailNav];
	}
}

#pragma mark - stop routes view controller delegate

- (void)stopRoutesViewController:(GRTStopRoutesViewController *)stopRoutesViewController didSelectRoute:(GRTRoute *)route
{
	GRTStopTimesViewController *stopTimesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopTimesView"];
	stopTimesVC.delegate = self;
	stopTimesVC.stopDetailsManager = [[GRTStopDetailsManager alloc] initWithStopDetails:self.stopDetailsManager.stopDetails route:route];
	stopTimesVC.stopDetailsManager.dayInWeek = self.stopDetailsManager.dayInWeek;
	stopTimesVC.stopDetailsManager.date = self.stopDetailsManager.date;
	[self.navigationController pushViewController:stopTimesVC animated:YES];
}

@end
