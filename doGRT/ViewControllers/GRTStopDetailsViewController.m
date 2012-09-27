//
//  GRTStopDetailsViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

#import "GRTStopDetailsViewController.h"

#import "GRTGtfsSystem.h"

@interface GRTStopDetailsViewController ()

@end

@implementation GRTStopDetailsViewController

@synthesize stopTimes = _stopTimes;

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
	
	NSAssert(self.stopTimes != nil, @"Must have a stopTimes");
	
	self.title = self.stopTimes.stop.stopName;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
