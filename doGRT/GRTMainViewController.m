//
//  GRTMainViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTMainViewController.h"
#import "GRTRouteTimeViewController.h"

#import "GRTBusInfo.h"
#import "GRTTimeTableEntry.h"
#import "GRTTripEntry.h"

@interface GRTMainViewController ()
@property (retain, nonatomic) MFMessageComposeViewController *messageComposeViewController;
//@property (assign, nonatomic) NSInteger curTime;
@property (assign, nonatomic) NSInteger comingBusIndex;
@property (retain, nonatomic) NSMutableArray *timeTableArray;
@property (retain, nonatomic) NSMutableArray *routeArray;
@property (retain, nonatomic) GRTBusInfo *busInfo;
@property (assign, nonatomic) BOOL isMixed;
@property (retain, nonatomic) NSNumber *chosenIndex;

@end


@implementation GRTMainViewController

// outlets
@synthesize sendTextButton = _sendTextButton;

// properties
@synthesize busStopNumber = _busStopNumber;
@synthesize busStopName = _busStopName;

// private properties
@synthesize messageComposeViewController = _messageComposeViewController;
//@synthesize curTime = _curTime;
@synthesize comingBusIndex = _comingBusIndex;
@synthesize timeTableArray = _timeTableArray;
@synthesize routeArray = _routeArray;
@synthesize busInfo = _busInfo;
@synthesize chosenIndex = _chosenIndex;
@synthesize isMixed = _isMixed;

- (GRTBusInfo *) busInfo{
	if(_busInfo == nil){
//		NSLog(@"Creating GRTBusInfo Instance");
		_busInfo = [[GRTBusInfo alloc] initByStop:self.busStopNumber];
	}
	return _busInfo;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View Update

- (void)updateTitle{
	self.title = [NSString stringWithFormat:@"%@", self.busStopName];
}

- (void)updateLoading{
	self.title = @"Loading...";
}

- (void)updateTimeTable{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:[NSDate date]];	
	NSInteger curTime = comps.hour * 10000 + comps.minute * 100 + comps.second;
	
	self.timeTableArray = [[self.busInfo getCurrentTimeTable] mutableCopy];
	
	self.comingBusIndex = [[self.timeTableArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departureTime<=%d", curTime, nil]] count];
}

- (void)updateRouteTable{
	self.routeArray = [[GRTBusInfo getRoutesByStop:self.busStopNumber] mutableCopy];
}

- (void)updateTable{
	[self updateLoading];
	if(self.isMixed && self.timeTableArray == nil) {
		[self updateTimeTable];
	}
	if(self.routeArray == nil){
		[self updateRouteTable];
	}
	[self updateTitle];
	[self.tableView reloadData];
	
	if(self.isMixed && self.comingBusIndex > 3){
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.comingBusIndex - 3 inSection:0];
		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
	}
}

- (BOOL)updateView{
	if([self.busStopNumber integerValue] == 0){
		[self.navigationController popViewControllerAnimated:YES];
		return NO;
	}
	return YES;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc]
												initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
												target:nil action:nil];
	
	// Create and configure the segmented control
	UISegmentedControl *displayToggle = [[UISegmentedControl alloc]
										 initWithItems:[NSArray arrayWithObjects:@"Routes List",
														@"Mixed Schedule", nil]];
	displayToggle.segmentedControlStyle = UISegmentedControlStyleBar;
	displayToggle.selectedSegmentIndex = 0;
	[displayToggle addTarget:self action:@selector(toggleDisplay:) 
			forControlEvents:UIControlEventValueChanged];
	
	// Create the bar button item for the segmented control
	UIBarButtonItem *displayToggleButtonItem = [[UIBarButtonItem alloc]
												initWithCustomView:displayToggle];
	
	// Set our toolbar items
	self.toolbarItems = [NSArray arrayWithObjects:
                         flexibleSpaceButtonItem,
                         displayToggleButtonItem,
                         flexibleSpaceButtonItem,
                         nil];
	
	if([MFMessageComposeViewController canSendText]){
		self.sendTextButton.enabled = true;
	}
	else {
		self.sendTextButton.enabled = false;
	}
	
	self.isMixed = NO;
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
	if([self updateView]){
		[self updateTable];
	}
	[self updateTitle];
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
	return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Sending Text View

- (IBAction)sendTextToGrtWhenClick:(UIBarButtonItem *)sender{
	if([MFMessageComposeViewController canSendText]){
		self.messageComposeViewController = [[MFMessageComposeViewController alloc] init];
	}
	else {
		return;
	}
	if(self.messageComposeViewController == nil){
		abort();
	}
	self.messageComposeViewController.recipients = [NSArray arrayWithObject:@"57555"];
	self.messageComposeViewController.body = [NSString stringWithFormat:@"%@", self.busStopNumber];
	self.messageComposeViewController.messageComposeDelegate = self;
	[self presentModalViewController:self.messageComposeViewController animated:YES];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table View Delegate

- (IBAction)toggleDisplay:(UISegmentedControl *)sender{
	self.isMixed = (sender.selectedSegmentIndex == 1);
	[self updateTable];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(self.isMixed){
		return 2;
	}
	else {
		return 1;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *title;
	if (!self.isMixed) {
		title = nil;
	}
	else if (section == 0) {
		title = @"Left Buses";
	}
	else if (section == 1) {
		title = @"Coming Buses";
	}
	return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger result;
	if(!self.isMixed) {
		result = [self.routeArray count];
	}
	else if (section == 0) {
		result = self.comingBusIndex;
	}
	else {
		result = [self.timeTableArray count] - self.comingBusIndex;
	}
	return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellIdentifier = nil;
	
	if(!self.isMixed) {
		cellIdentifier = @"routeCell";
	}
	else if (indexPath.section == 0) {
		cellIdentifier = @"leftTimeTableCell";
	}
	else if (indexPath.section == 1) {
		cellIdentifier = @"timeTableCell";
	}
	 
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
    if(self.isMixed) {
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
		cell.textLabel.text = [NSString stringWithFormat:@"%02d:%02d", time / 10000, (time / 100) % 100 ];
	}
	else {
		GRTTripEntry *entry = (GRTTripEntry *)[self.routeArray objectAtIndex:indexPath.row];
		cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", entry.routeId, entry.routeLongName];
	}
	
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	self.chosenIndex = [NSNumber numberWithInteger:indexPath.row];
	return indexPath;
}

#pragma mark - Segue setting

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([[segue identifier] isEqualToString:@"showRouteTime"]) {
		GRTRouteTimeViewController *vc = (GRTRouteTimeViewController *)[segue destinationViewController];
		assert([vc isKindOfClass:[GRTRouteTimeViewController class]]);
		GRTTripEntry *route = (GRTTripEntry *) [self.routeArray objectAtIndex:[self.chosenIndex unsignedIntegerValue]];
		
		vc.busInfo = self.busInfo;
		vc.route = route;
	}
}

@end
