//
//  GRTAddingViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTAddingViewController.h"
#import "GRTBusInfo.h"
#import "GRTBusStopEntry.h"
#import "GRTMapAnnotation.h"

@interface GRTAddingViewController()
@property (assign, nonatomic) BOOL stopLocating;
@property (assign, nonatomic) CLLocationCoordinate2D lastCenter;
@property (assign, nonatomic) MKCoordinateSpan lastSpan;
@end

@implementation GRTAddingViewController

@synthesize delegate = _delegate;

@synthesize saveButton = _saveButton;
@synthesize navigationBar = _navigationBar;
@synthesize busStopNumberText = _busStopNumberText;
@synthesize mapView = _mapView;

@synthesize stopLocating = _stopLocating;
@synthesize lastCenter = _lastCenter;
@synthesize lastSpan = _lastSpan;

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

#pragma mark - View Update

- (void)updateMapView:(MKMapView *)mapView 
		 withLocation:(CLLocationCoordinate2D)coordinate
			  andSpan:(MKCoordinateSpan)span{
//	[self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
	[mapView setRegion:MKCoordinateRegionMake(coordinate, span) 
			  animated:YES];
}

- (void)updateMapView:(MKMapView *)mapView inRegion:(MKCoordinateRegion)region{
	// if didn't move, stop updating
	if(self.lastCenter.latitude == mapView.region.center.latitude && 
	   self.lastCenter.longitude == mapView.region.center.longitude &&
	   self.lastSpan.latitudeDelta == mapView.region.span.latitudeDelta &&
	   self.lastSpan.longitudeDelta == mapView.region.span.longitudeDelta){
		return;
	}
	
	// record the this region as last
	self.lastCenter = mapView.region.center;
	self.lastSpan = mapView.region.span;
	
	// find out all need to remove annotations
	NSMutableArray *toRemove = [NSMutableArray arrayWithCapacity:50];
	for (id annotation in mapView.annotations){
		if ([annotation isKindOfClass:[GRTMapAnnotation class]]){			
			[toRemove addObject:annotation];
		}
	}
	[mapView removeAnnotations:toRemove];
	
	// get bus stops in current region	
	NSArray *busStops = [GRTBusInfo getBusStopsAt:self.lastCenter 
										   inSpan:self.lastSpan withLimit:40];
	
	// add bus stops to the annotations
	GRTBusStopEntry *busStop = nil;
	GRTMapAnnotation *annotation = nil;
	for(busStop in busStops){
		CLLocationCoordinate2D coordinate = 
		CLLocationCoordinate2DMake([busStop.stopLat doubleValue], 
								   [busStop.stopLon doubleValue]);
		annotation = 
			[[GRTMapAnnotation alloc] initAtCoordinate:coordinate 
											 withTitle:busStop.stopName 
										  withSubtitle:[NSString stringWithFormat:@"%@", busStop.stopId]];
		
		[mapView addAnnotation:annotation];
	}

}

- (void)updateView{

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.navigationBar.title = @"Add a Bus Stop";
	self.saveButton.enabled = NO;
	
	[self updateMapView:self.mapView withLocation:CLLocationCoordinate2DMake(43.47273, -80.541218) andSpan:MKCoordinateSpanMake(0.05, 0.05)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	[self.mapView setUserTrackingMode:MKUserTrackingModeFollow];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)valueChanged:(UITextField *)sender{
	if([self.busStopNumberText.text length] == 0){
		self.saveButton.enabled = NO;
	}
	else if([self.busStopNumberText.text length] == 4){
		self.saveButton.enabled = YES;
		// TODO: show the stop location on the map view
	}
	else if([self.busStopNumberText.text length] > 4){
		self.busStopNumberText.text = [self.busStopNumberText.text substringToIndex:4];
	}
}

- (IBAction)cancel:(UIBarButtonItem *)sender{
	[self.delegate addingViewControllerDidFinishWithBusStopNumber:0 
												  withBusStopName:@""];
}

- (IBAction)save:(UIBarButtonItem *)sender{
	NSNumber *busStopNumber = [NSNumber numberWithInteger:[self.busStopNumberText.text integerValue]];
	
	// Check non-digit characters
	if([busStopNumber integerValue] == 0){
		self.busStopNumberText.text = @"";
		return;
	}
	
	// Loop up stop number for name
	NSString *busStopName = [GRTBusInfo getBusStopNameById:busStopNumber];
	
	// Check invalid stop number
	if(busStopName == nil){
		self.busStopNumberText.text = @"";
		return;
	}
	
	[self.delegate addingViewControllerDidFinishWithBusStopNumber:busStopNumber 
												  withBusStopName:busStopName];
}

#pragma mark - Map View Delegate

//- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
//	[self updateMapView:mapView 
//		   withLocation:userLocation.location.coordinate
//				andSpan:MKCoordinateSpanMake(0.005, 0.005)];
//}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
	[self updateMapView:mapView inRegion:mapView.region];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
	self.busStopNumberText.text = view.annotation.subtitle;
	[self valueChanged:self.busStopNumberText];
}


@end
