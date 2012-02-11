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

@interface GRTRouteTimeViewController ()
@property (assign, nonatomic) NSInteger curTime;
@property (retain, nonatomic) NSMutableArray *timeTableArray;

@end

@implementation GRTRouteTimeViewController

@synthesize tableCell = _tableCell;
@synthesize busInfo = _busInfo;
@synthesize route = _route;

@synthesize curTime = _curTime;
@synthesize timeTableArray = _timeTableArray;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View Update

- (void)updateTitle{
	self.title = [NSString stringWithFormat:@"%@ %@", self.route.routeId, self.route.routeLongName];
}

- (void)updateLoading{
	self.title = @"Loading...";
}

- (void)updateTimeTable{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:[NSDate date]];	
	self.curTime = comps.hour * 10000 + comps.minute * 100 + comps.second;
	
	self.timeTableArray = [[self.busInfo getCurrentTimeTableByRoute:[self.route routeId]] mutableCopy];
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES; // (interfaceOrientation == UIInterfaceOrientationPortrait);
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
        cell = self.tableCell;
        self.tableCell = nil;
    }
	
	GRTTimeTableEntry *entry = (GRTTimeTableEntry *)[self.timeTableArray objectAtIndex:indexPath.row];
	
	NSInteger time = [entry.departureTime integerValue];
	
	if(time < self.curTime){
		cell.detailTextLabel.textColor = [UIColor colorWithRed:150.0/255 green:150.0/255 blue:150.0/255 alpha:1];
	}
	else {
		cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
	}
	
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


@end
