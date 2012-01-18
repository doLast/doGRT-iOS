//
//  GRTStartingViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-1-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTStartingViewController.h"
//#import "GRTCVSParsing.h"

@implementation GRTStartingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	
//	if([[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"] ||
//	   [[NSUserDefaults standardUserDefaults] integerForKey:@"dataVersion"] < 201201){
//		GRTCVSParsing *parser = [[GRTCVSParsing alloc] init];
//		[parser parseAll];
//		
//		[[NSUserDefaults standardUserDefaults] 
//		 setValue:[NSNumber numberWithInteger: 201201] forKey:@"dataVersion"];
//		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstLaunch"];
//	}
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstLaunch"];
	[self performSegueWithIdentifier:@"showMain" sender:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
