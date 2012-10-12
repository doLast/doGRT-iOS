//
//  GRTStopDetailsViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

#import "GRTStopDetailsViewController.h"
#import "UINavigationController+Rotation.h"
#import "GRTStopsMapViewController.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopDetailsViewController ()

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) GRTFavoriteStop *favoriteStop;
@property (nonatomic, strong) NSArray *candidateViewControllers;

@end

@implementation GRTStopDetailsViewController

@synthesize stopTimes = _stopTimes;
@synthesize viewsSegmentedControl = _viewsSegmentedControl;
@synthesize favButton = _favButton;

@synthesize date = _date;
@synthesize favoriteStop = _favoriteStop;
@synthesize candidateViewControllers = _candidateViewControllers;

- (void)setFavoriteStop:(GRTFavoriteStop *)favoriteStop
{
	_favoriteStop = favoriteStop;
	if (_favoriteStop != nil) {
		self.favButton.title = @"Remove Fav";
	}
	else {
		self.favButton.title = @"Add to Fav";
	}
}

#pragma mark - view life-cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.delegate = self;
	self.dataSource = self;
	for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
		if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
			recognizer.enabled = NO;
		}
	}
	
	NSAssert(self.stopTimes != nil, @"Must have a stopTimes");
	
	self.title = self.stopTimes.stop.stopName;
	self.date = [NSDate date];
	self.favoriteStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:self.stopTimes.stop];
	self.view.backgroundColor = [UIColor underPageBackgroundColor];
	
	GRTStopTimesViewController *stopTimesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopTimesView"];
	stopTimesVC.stopTimes = [self.stopTimes stopTimesForDate:self.date];
	stopTimesVC.delegate = self;
	
	GRTStopRoutesViewController *stopRoutesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopRoutesView"];
	stopRoutesVC.routes = [self.stopTimes routes];
	stopRoutesVC.delegate = self;
	
	self.candidateViewControllers = [NSArray arrayWithObjects:stopTimesVC, stopRoutesVC, nil];
	
	NSInteger index = 0; // TODO: Let user choose default view
	[self setViewControllers:@[[self.candidateViewControllers objectAtIndex:index]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
	[self.viewsSegmentedControl setSelectedSegmentIndex:index];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

#pragma mark - actions

- (IBAction)toggleViews:(id)sender
{
	NSInteger old = [self.candidateViewControllers indexOfObject:[self.viewControllers objectAtIndex:0]];
	NSInteger new = (old + 1) % [self.candidateViewControllers count];
	NSLog(@"Transmiting from #%d to #%d", old, new);
	
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

#pragma mark - page view data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
	NSInteger index = [self.candidateViewControllers indexOfObject:viewController];
	if (index == 1) {
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
		
		GRTStopsMapViewController *tripDetailsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"tripDetailsView"];
		tripDetailsVC.title = [NSString stringWithFormat:@"%@ %@", stopTime.trip.route.routeId, stopTime.trip.tripHeadsign];
		tripDetailsVC.inRegionStopsDisplayThreshold = 0.03;
		[self.navigationController pushViewController:tripDetailsVC animated:YES];
		
		tripDetailsVC.shape = stopTime.trip.shape;
		tripDetailsVC.stops = [[GRTGtfsSystem defaultGtfsSystem] stopTimesForTrip:stopTime.trip];
		
		NSUInteger stopTimeIndex = [tripDetailsVC.stops indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
			GRTStopTime *stopTimeObj = obj;
			if (stopTimeObj.stopSequence.integerValue == stopTime.stopSequence.integerValue) {
				*stop = YES;
				return YES;
			}
			return NO;
		}].firstIndex;
		[tripDetailsVC selectStop:[tripDetailsVC.stops objectAtIndex:stopTimeIndex]];
	}
}

#pragma mark - stop routes view controller delegate

- (void)stopRoutesViewController:(GRTStopRoutesViewController *)stopRoutesViewController didSelectRoute:(GRTRoute *)route
{
	GRTStopTimesViewController *stopTimesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopTimesView"];
	stopTimesVC.stopTimes = [self.stopTimes stopTimesForDate:self.date andRoute:route];
	stopTimesVC.title = [NSString stringWithFormat:@"%@ %@", route.routeId, route.routeLongName];
	[self.navigationController pushViewController:stopTimesVC animated:YES];
}

@end
