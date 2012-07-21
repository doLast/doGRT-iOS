//
//  GRTRouteMapViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-4-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTRouteMapViewController.h"
#import "GRTMainViewController.h"

#import "GRTBusInfo.h"
#import "GRTTripEntry.h"
#import "GRTBusStopEntry.h"

@implementation GRTRouteMapViewController

@synthesize mapView = _mapView;
@synthesize route = _route;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View Update

- (void)updateMapView:(MKMapView *)mapView 
		 withLocation:(CLLocationCoordinate2D)coordinate
			  andSpan:(MKCoordinateSpan)span{
	[mapView setRegion:MKCoordinateRegionMake(coordinate, span) 
			  animated:YES];
}

- (void)setupMapView:(MKMapView *)mapView forRouteId:(NSString *)routeId{
	
	// get bus stops in current region	
	NSArray *stops = [GRTBusInfo getBusStopsByRouteId:routeId];
		
	[mapView addAnnotations:stops];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	[self updateMapView:self.mapView withLocation:CLLocationCoordinate2DMake(43.47273, -80.541218) andSpan:MKCoordinateSpanMake(0.02, 0.02)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.title = @"Loading...";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	if([self.mapView.annotations count] < 2){
		self.mapView.userTrackingMode = MKUserTrackingModeFollow;
		[self setupMapView:self.mapView forRouteId:self.route.routeId];
	}
	
	self.title = [NSString stringWithFormat:@"%@ %@", self.route.routeId, self.route.routeLongName];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES; // (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Map View Delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
	self.mapView.userTrackingMode = MKUserTrackingModeNone;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views{
	for (MKAnnotationView *view in views) {
		if([view.annotation isKindOfClass:[GRTBusStopEntry class]]) view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	}
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
	[self performSegueWithIdentifier:@"showMain" sender:view];
}

#pragma mark - Segue setting

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([[segue identifier] isEqualToString:@"showMain"] && 
	   [sender isKindOfClass:[MKAnnotationView class]]) {
		GRTMainViewController *vc = (GRTMainViewController *)[segue destinationViewController];
		
		MKAnnotationView *annotationView = (MKAnnotationView *)sender;
		
		vc.busStopNumber = [NSNumber numberWithInteger:[annotationView.annotation.subtitle integerValue]];
		vc.busStopName = annotationView.annotation.title;
	}
}


@end
