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

@interface GRTStopDetailsViewController ()

@property (nonatomic, strong) GRTFavoriteStop *favoriteStop;
@property (nonatomic, strong) GRTStopTimesViewController *stopTimesViewController;
@property (nonatomic, strong) GRTStopRoutesViewController *stopRoutesViewController;
@property (nonatomic, strong) NSArray *candidateViewControllers;

@end

@implementation GRTStopDetailsViewController

@synthesize stopDetailsManager = _stopDetailsManager;
@synthesize viewsSegmentedControl = _viewsSegmentedControl;
@synthesize favButton = _favButton;

@synthesize favoriteStop = _favoriteStop;
@synthesize stopTimesViewController = _stopTimesViewController;
@synthesize stopRoutesViewController = _stopRoutesViewController;
@synthesize candidateViewControllers = _candidateViewControllers;

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


#pragma mark - view life-cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Config page view
	self.delegate = self;
	self.dataSource = self;
	for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
		if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
			recognizer.enabled = NO;
		}
	}
	
	// Prepare data for views construction
	NSAssert(self.stopDetailsManager != nil, @"Must have a stopTimes");
	
	self.favoriteStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:self.stopDetailsManager.stopDetails.stop];
	self.view.backgroundColor = [UIColor underPageBackgroundColor];
	[self.favButton setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:17.0] forKey:UITextAttributeFont] forState:UIControlStateNormal];
	
	// Construct view controllers
	GRTStopTimesViewController *stopTimesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopTimesView"];
	stopTimesVC.delegate = self;
	
	GRTStopRoutesViewController *stopRoutesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopRoutesView"];
	stopRoutesVC.routes = [self.stopDetailsManager.stopDetails routes];
	stopRoutesVC.delegate = self;
	
	// Assign view controllers
	self.candidateViewControllers = @[stopTimesVC, stopRoutesVC];
	self.stopTimesViewController = stopTimesVC;
	self.stopRoutesViewController = stopRoutesVC;
	
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
	[self setViewControllers:@[[self.candidateViewControllers objectAtIndex:index.integerValue]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
	[self.viewsSegmentedControl setSelectedSegmentIndex:index.integerValue];
	
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

- (IBAction)toggleViews:(id)sender
{
	NSInteger old = [self.candidateViewControllers indexOfObject:[self.viewControllers objectAtIndex:0]];
	NSInteger new = (old + 1) % [self.candidateViewControllers count];
	
	UIPageViewControllerNavigationDirection direction = new < old ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward;
	
	[self setViewControllers:@[[self.candidateViewControllers objectAtIndex:new]] direction:direction animated:YES completion:nil];
	
	// TODO: Toggling the view too fast will cause crash
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

#pragma mark - page view data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
	NSInteger index = [self.candidateViewControllers indexOfObject:viewController];
	if (index == [self.candidateViewControllers count] - 1) {
		return nil;
	}
	index = (index + 1) % [self.candidateViewControllers count];
	
	return [self.candidateViewControllers objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
	NSInteger index = [self.candidateViewControllers indexOfObject:viewController];
	if (index == 0) {
		return nil;
	}
	index = (index - 1) % [self.candidateViewControllers count];
	
	return [self.candidateViewControllers objectAtIndex:index];
}

#pragma mark - page view delegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
	NSInteger index = [self.candidateViewControllers indexOfObject:[self.viewControllers objectAtIndex:0]];
	[self.viewsSegmentedControl setSelectedSegmentIndex:index];
}

#pragma mark - stop times view controller delegate

- (void)stopTimesViewController:(GRTStopTimesViewController *)stopTimesViewController didSelectStopTime:(GRTStopTime *)stopTime
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[stopTimesViewController showTripDetailsForStopTime:stopTime inNavigationController:self.navigationController];
	}
	else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *detailNav = (id)[self.splitViewController.viewControllers objectAtIndex:1];
		[detailNav popToRootViewControllerAnimated:NO];
		[stopTimesViewController showTripDetailsForStopTime:stopTime inNavigationController:detailNav];
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
