//
//  GRTBusStopsViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import "GRTBusStopsViewController.h"
#import "UINavigationController+Rotation.h"

@interface GRTBusStopsViewController ()

@end

@implementation GRTBusStopsViewController

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
	// Do any additional setup after loading the view.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.mapView.hidden = YES;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
			[self.navigationController setNavigationBarHidden:YES animated:NO];
			self.mapView.hidden = NO;
		}
		else {
			self.mapView.hidden = YES;
			[self.navigationController setNavigationBarHidden:NO animated:NO];
		}
	}
}

@end
