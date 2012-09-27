//
//  GRTStopDetailsViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

#import "GRTStopDetailsViewController.h"
#import "GRTStopTimesViewController.h"
#import "GRTStopRoutesViewController.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopDetailsViewController ()

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) GRTFavoriteStop *favoriteStop;
@property (nonatomic, strong) GRTStopTimesViewController *stopTimesVC;
@property (nonatomic, strong) GRTStopRoutesViewController *stopRoutesVC;

@end

@implementation GRTStopDetailsViewController

@synthesize stopTimes = _stopTimes;
@synthesize stopTimesVC = _stopTimesVC;

#pragma mark - view life-cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.delegate = self;
	self.dataSource = self;
	
	NSAssert(self.stopTimes != nil, @"Must have a stopTimes");
	
	self.title = self.stopTimes.stop.stopName;
	self.date = [NSDate date];
	self.favoriteStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:self.stopTimes.stop];
	
	self.stopTimesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopTimesView"];
	self.stopTimesVC.stopTimes = [self.stopTimes stopTimesForDate:self.date];
	
	self.stopRoutesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"stopRoutesView"];
	
	[self setViewControllers:[NSArray arrayWithObjects:self.stopTimesVC, nil] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

#pragma mark - actions

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

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
	if (viewController == self.stopTimesVC) {
		return self.stopRoutesVC;
	}
	return self.stopTimesVC;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
	if (viewController == self.stopTimesVC) {
		return self.stopRoutesVC;
	}
	return self.stopTimesVC;
}

@end
