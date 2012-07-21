//
//  GRTAddingViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTAddingViewController.h"
#import "GRTStopListViewController.h"
#import "GRTMainViewController.h"

#import "GRTBusInfo.h"
#import "GRTBusStopEntry.h"

@interface GRTAddingViewController()
@property (assign, nonatomic) BOOL stopLocating;
@property (retain, nonatomic) NSArray *searchResult;
@property (retain, nonatomic) NSNumber *selectedBusStopId;
@property (retain, nonatomic) NSString *selectedBusStopName;
@end

@implementation GRTAddingViewController

@synthesize saveButton = _saveButton;
@synthesize mapView = _mapView;

@synthesize stopLocating = _stopLocating;
@synthesize searchResult = _searchResult;
@synthesize selectedBusStopId = _selectedBusStopId;
@synthesize selectedBusStopName = _selectedBusStopName;

#pragma mark - View Update

- (void)updateMapView:(MKMapView *)mapView 
		 withLocation:(CLLocationCoordinate2D)coordinate
			  andSpan:(MKCoordinateSpan)span{
	if (self.selectedBusStopId != nil) {
		for (id <MKAnnotation> annotation in mapView.annotations) {
			if ([annotation.subtitle integerValue] == [self.selectedBusStopId integerValue]) {
				NSLog(@"Found in old");
				[mapView selectAnnotation:annotation animated:YES];
			}
		}
	}
	[mapView setRegion:MKCoordinateRegionMake(coordinate, span) 
			  animated:YES];
}

- (void)updateMapView:(MKMapView *)mapView inRegion:(MKCoordinateRegion)region{
		
	// find out all need to remove annotations	
	NSSet *visibleAnnotations = [mapView annotationsInMapRect:[mapView visibleMapRect]];
	NSSet *allAnnotations = [NSSet setWithArray:mapView.annotations];
	NSMutableSet *nonVisibleAnnotations = [NSMutableSet setWithSet:allAnnotations];
	[nonVisibleAnnotations minusSet:visibleAnnotations];
	[nonVisibleAnnotations filterUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [GRTBusStopEntry class]]];
	[mapView removeAnnotations:[nonVisibleAnnotations allObjects]];
	
	// find whether the selected bus stop is in visibleAnnotations
	if (self.selectedBusStopId != nil) {
		for (id <MKAnnotation> annotation in mapView.annotations) {
			if ([annotation.subtitle integerValue] == [self.selectedBusStopId integerValue]) {
				[mapView selectAnnotation:annotation animated:YES];
			}
		}
	}
	
	// if not too many annotations currently on the map
	if([[mapView annotations] count] < 50){
		// get bus stops in current region	
		NSArray *newStops = [GRTBusInfo getBusStopsAt:mapView.region.center
											   inSpan:mapView.region.span
											withLimit:50];

		NSMutableSet *newAnnotations = [NSMutableSet setWithArray:newStops];
		[newAnnotations minusSet:visibleAnnotations];
		
		[mapView addAnnotations:[newAnnotations allObjects]];
	}
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	self.title = @"Add a Bus Stop";
	self.saveButton.enabled = NO;
	self.selectedBusStopId = nil;
	
	[self updateMapView:self.mapView withLocation:CLLocationCoordinate2DMake(43.47273, -80.541218) andSpan:MKCoordinateSpanMake(0.05, 0.05)];
	
	self.stopLocating = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	if(!self.stopLocating) {
		self.mapView.userTrackingMode = MKUserTrackingModeFollow;
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	self.stopLocating = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Actions

- (IBAction)save:(UIBarButtonItem *)sender{
	if (self.selectedBusStopId == nil || self.selectedBusStopName == nil) {
		return;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kGRTAddNewBusStopNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.selectedBusStopId, kGRTAddNewBusStopNotificationStopId, self.selectedBusStopName, kGRTAddNewBusStopNotificationStopName, nil]];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Map View Delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	[self updateMapView:mapView inRegion:mapView.region];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	self.mapView.userTrackingMode = MKUserTrackingModeNone;
	self.selectedBusStopId = [NSNumber numberWithInteger:[view.annotation.subtitle integerValue]];
	self.selectedBusStopName = view.annotation.title;
	self.saveButton.enabled = YES;
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
	self.saveButton.enabled = NO;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
	for (MKAnnotationView *view in views) {
		if ([view.annotation isKindOfClass:[GRTBusStopEntry class]]) { 
			view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		}
	}
	if (self.selectedBusStopId != nil) {
		for (MKAnnotationView *view in views) {
			if ([view.annotation.subtitle integerValue] == [self.selectedBusStopId integerValue]) {
				[mapView selectAnnotation:view.annotation animated:YES];
			}
		}
	}
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	[self performSegueWithIdentifier:@"showMain" sender:view];
}

#pragma mark - Search Dsiplay Delegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	self.selectedBusStopId = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{	
	if (controller.isActive == YES && [searchString length] > 1) {
		self.searchResult = [GRTBusInfo getBusStopsLike:searchString];
		return YES;
	}
	
	return NO;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.saveButton.enabled = NO;
	GRTBusStopEntry *stop = [self.searchResult objectAtIndex:indexPath.row];
	self.selectedBusStopId = stop.stopId;
	[self.searchDisplayController setActive:NO animated:YES];
	[self updateMapView:self.mapView withLocation:CLLocationCoordinate2DMake([stop.stopLat doubleValue], [stop.stopLon doubleValue]) andSpan:MKCoordinateSpanMake(0.01, 0.01)];
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.searchResult count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"busStopCell";
	UITableViewCell *cell= [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
									  reuseIdentifier:CellIdentifier];
    }
	
	GRTBusStopEntry *stop = [self.searchResult objectAtIndex:indexPath.row];
	cell.textLabel.text = stop.stopName;
	cell.detailTextLabel.text = stop.stopId.description;
	
	return cell;
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
