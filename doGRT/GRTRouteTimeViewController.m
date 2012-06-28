//
//  GRTRouteTimeViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-2-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTRouteTimeViewController.h"

#import "GRTBusInfo.h"
#import "GRTTripEntry.h"
#import "GRTTimeTableEntry.h"
#import "GRTRouteMapViewController.h"

@interface GRTRouteTimeViewController ()
//@property (assign, nonatomic) NSInteger curTime;
@property (assign, nonatomic) NSInteger comingBusIndex;
@property (retain, nonatomic) NSMutableArray *timeTableArray;

@end

@implementation GRTRouteTimeViewController

@synthesize busInfo = _busInfo;
@synthesize route = _route;

//@synthesize curTime = _curTime;
@synthesize comingBusIndex = _comingBusIndex;
@synthesize timeTableArray = _timeTableArray;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View Update

- (void)updateTitle{
	self.title = [NSString stringWithFormat:@"%@", self.route.routeId];
}

- (void)updateLoading{
	self.title = @"Loading...";
}

- (void)updateTimeTable{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:[NSDate date]];	
	NSInteger curTime = comps.hour * 10000 + comps.minute * 100 + comps.second;
		
	self.timeTableArray = [[self.busInfo getCurrentTimeTableByRoute:self.route.routeId] mutableCopy];
	
	self.comingBusIndex = [[self.timeTableArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departureTime<=%d", curTime, nil]] count];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self updateLoading];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	[self updateTimeTable];
	[self.tableView reloadData];
	[self updateTitle];
	
	if (self.comingBusIndex > 1) {
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.comingBusIndex - 1 inSection:0];
		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES; // (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title;
	if (section == 0) {
		title = @"Left Buses";
	}
	else if (section == 1) {
		title = @"Coming Buses";
	}
	return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (section == 0) {
		return self.comingBusIndex;
	}
	else {
		return [self.timeTableArray count] - self.comingBusIndex;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	
	static NSString *cellIdentifier;
	if(indexPath.section == 0){
		cellIdentifier = @"leftTimeTableCell";
	}
	else if (indexPath.section == 1) {
		cellIdentifier = @"timeTableCell";
	}
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	GRTTimeTableEntry *entry = (GRTTimeTableEntry *)[self.timeTableArray objectAtIndex:indexPath.row + (self.comingBusIndex * indexPath.section)];
	
	NSInteger time = [entry.departureTime integerValue];
	if(time >= 240000){
		time -= 240000;
	}
	else if(time < 0){
		time += 240000;
	}
	NSString *tripName = [NSString stringWithFormat:@"%@ %@", entry.routeId, entry.tripHeadsign];
	
	cell.detailTextLabel.text = tripName;
	cell.textLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", time / 10000, (time / 100) % 100, time % 100 ];
	
    return cell;
}

#pragma mark - Segue setting

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"showRouteMap"]) {
		GRTRouteMapViewController *vc = (GRTRouteMapViewController *)[segue destinationViewController];
		assert([vc isKindOfClass:[GRTRouteMapViewController class]]);
		vc.route = self.route;
	}
}


@end
