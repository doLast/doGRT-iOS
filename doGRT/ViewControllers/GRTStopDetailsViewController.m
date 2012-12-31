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

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopDetailsViewController ()

@property (nonatomic, strong) GRTFavoriteStop *favoriteStop;
@property (nonatomic, strong) GRTStopTimesViewController *stopTimesViewController;
@property (nonatomic, strong) GRTStopRoutesViewController *stopRoutesViewController;
@property (nonatomic, strong) NSArray *candidateViewControllers;

@end

@implementation GRTStopDetailsViewController

@synthesize stopTimes = _stopTimes;
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
	NSAssert(self.stopTimes != nil, @"Must have a stopTimes");
	
	self.title = self.stopTimes.stop.stopName;
	self.favoriteStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:self.stopTimes.stop];
	self.view.backgroundColor = [UIColor underPageBackgroundColor];
	[self.favButton setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:17.0] forKey:UITextAttributeFont] forState:UIControlStateNormal];
	
	// Construct view controllers
	GRTStopTimesViewController *stopTimesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopTimesView"];
	stopTimesVC.stopTimes = [self.stopTimes stopTimesForDate:[NSDate date]];
	stopTimesVC.delegate = self;
	
	GRTStopRoutesViewController *stopRoutesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopRoutesView"];
	stopRoutesVC.routes = [self.stopTimes routes];
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
	GRTDetailedTitleButtonView *titleView = [[GRTDetailedTitleButtonView alloc] initWithText:self.title detailText:@"Today ▾"];
	[titleView addTarget:self action:@selector(showModePicker:) forControlEvents:UIControlEventTouchUpInside];
	[self.navigationItem setTitleView:titleView];
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
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
		self.favoriteStop = [[GRTUserProfile defaultUserProfile] addStop:self.stopTimes.stop];
	}
}

- (IBAction)showModePicker:(id)sender
{
	CGPoint point = CGPointMake(self.view.frame.size.width / 2.0, 0.0f);
	PopoverView *popoverView = [PopoverView showPopoverAtPoint:point inView:self.view withStringArray:[NSArray arrayWithObjects:@"Today", @"Day in a week", /*@"Certain Date", */nil] delegate:self];
	popoverView.tag = 0;
}

- (IBAction)showDayPicker:(id)sender
{
	CGPoint point = CGPointMake(self.view.frame.size.width / 2.0, 0.0f);
	PopoverView *popoverView = [PopoverView showPopoverAtPoint:point inView:self.view withTitle:@"Pick a date" withStringArray:[NSArray arrayWithObjects: @"Sunday/Holiday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", nil] delegate:self];
	popoverView.tag = 1;
}

- (IBAction)showDatePicker:(id)sender
{
	CGPoint point = CGPointMake(self.view.frame.size.width / 2.0, 0.0f);
	// TODO: Use Calendar Instead
	PopoverView *popoverView = [PopoverView showPopoverAtPoint:point inView:self.view withTitle:@"Pick a date" withStringArray:[NSArray arrayWithObjects: @"Sunday/Holiday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", nil] delegate:self];
	popoverView.tag = 2;
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
	stopTimesVC.title = [NSString stringWithFormat:@"%@ %@", route.routeId, route.routeLongName];
	stopTimesVC.delegate = self;
	[self.navigationController pushViewController:stopTimesVC animated:YES];

	stopTimesVC.stopTimes = [self.stopTimes stopTimesForDate:[NSDate date] andRoute:route];
}

#pragma mark - popover view delegate

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
	NSUInteger tag = popoverView.tag;
	[popoverView dismiss];
	if (tag == 0) {
		switch (index) {
			case 1:
				[self showDayPicker:self];
				break;
			case 2:
				[self showDatePicker:self];
				break;
			default:
				self.stopTimesViewController.stopTimes = [self.stopTimes stopTimesForDate:[NSDate date]];
				break;
		}
	}
	else if (tag == 1) {
		self.stopTimesViewController.stopTimes = [self.stopTimes stopTimesForDayInWeek:index + 1];
	}
	// TODO: Handle other type of popovers
}

@end
