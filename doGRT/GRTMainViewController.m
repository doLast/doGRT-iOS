//
//  GRTMainViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTMainViewController.h"
#import "GRTBusInfo.h"
#import "GRTTimeTableEntry.h"

@interface GRTMainViewController ()
@property (retain, nonatomic) MFMessageComposeViewController *messageComposeViewController;
@end

@implementation GRTMainViewController

//@synthesize managedObjectContext = _managedObjectContext;
@synthesize sendTextButton = _sendTextButton;
@synthesize busStopNumber = _busStopNumber;
@synthesize lastBusStopNumber = _lastBusStopNumber;
@synthesize busStopName = _busStopName;
//@synthesize lastLeft = _lastLeft;
@synthesize curTime = _curTime;

@synthesize messageComposeViewController = _messageComposeViewController;

@synthesize timeTableCell = _timeTableCell;
@synthesize timeTableArray = _timeTableArray;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (NSString *) fillSpaceForString:(NSString *)str{
	return [@"    " substringFromIndex:[str length]];
}

#pragma mark - View Update

- (void)updateTitle{
	if([self.busStopNumber integerValue] == 0 ){
		self.title = @"No Stop Chosen";
	}
	else{
		self.title = [NSString stringWithFormat:@"%@", self.busStopName];
	}
	
	if([MFMessageComposeViewController canSendText]){
		self.sendTextButton.enabled = true;
	}
	else {
		self.sendTextButton.enabled = false;
	}
}

- (void)updateLoading{
	self.title = @"Loading...";
}

- (void)updateTimeTable{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:[NSDate date]];	
	self.curTime = comps.hour * 10000 + comps.minute * 100 + comps.second;
	if(self.lastBusStopNumber == nil || ![self.busStopNumber isEqualToNumber:self.lastBusStopNumber]){
		self.timeTableArray = [[NSMutableArray alloc] init];
		[self.tableView reloadData];
		GRTBusInfo *busInfo = [[GRTBusInfo alloc] init];
		self.timeTableArray = [[busInfo getCurrentTimeTableById:self.busStopNumber] mutableCopy];
		[self.tableView reloadData];
		
//		[self.tableView scrollToRowAtIndexPath:self.lastLeft atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
	self.lastBusStopNumber = self.busStopNumber;
}

- (BOOL)updateView{
	if([self.busStopNumber integerValue] == 0){
		[self performSegueWithIdentifier:@"showAlternate" sender:self];
		return NO;
	}
	return YES;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.busStopNumber = [NSNumber numberWithInteger:0];
	
	
//	The view should be update after appear, in order to let user choose a stop
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
		[self updateTimeTable];
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
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinishWithBusStopNumber:(NSNumber *)busStopNumber 
										 withBusStopName:(NSString *)busStopName
{
	self.busStopNumber = busStopNumber;
	self.busStopName = busStopName;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark - Sending Text View

- (IBAction)sendTextToGrtWhenClick:(UIBarButtonItem *)sender{
	if([MFMessageComposeViewController canSendText] && 
	   self.messageComposeViewController == nil){ 
		self.messageComposeViewController = [[MFMessageComposeViewController alloc] init];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.timeTableArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"timeTableCell";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = self.timeTableCell;
        self.timeTableCell = nil;
    }
	
    GRTTimeTableEntry *entry = (GRTTimeTableEntry *)[self.timeTableArray objectAtIndex:indexPath.row];
	
	NSInteger time = [entry.departureTime integerValue];
	
	NSString *leave = nil;
	if(time < self.curTime){
		cell.textLabel.textColor = [UIColor colorWithRed:255 green:0 blue:0 alpha:1];
		leave = @"Left";
//		self.lastLeft = indexPath;
	}
	else {
		cell.textLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
		leave = @"Leaving";
	}
	
	if(time >= 240000){
		time -= 240000;
	}
	else if(time < 0){
		time += 240000;
	}
	
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", entry.routeId, entry.tripHeadsign];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ at: %02d:%02d:%02d", leave, time / 10000, (time / 100) % 100, time % 100 ];
		
	
	
    return cell;
}

@end
