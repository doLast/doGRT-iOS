//
//  GRTStopRoutesViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-2-10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTStopRoutesViewController.h"
#import "GRTBusInfo.h"
#import "GRTTripEntry.h"

@interface GRTStopRoutesViewController ()
//@property (retain, nonatomic) GRTBusInfo *busInfo;
@property (retain, nonatomic) NSMutableArray *tripArray;

@end

@implementation GRTStopRoutesViewController

@synthesize tableView = _tableView;
@synthesize tableCell = _tableCell;
@synthesize navigationBar = _navigationBar;
@synthesize busStopNumber = _busStopNumber;

//@synthesize busInfo = _busInfo;
@synthesize tripArray = _tripArray;

//- (GRTBusInfo *) busInfo{
//	if(_busInfo == nil){
//		_busInfo = [[GRTBusInfo alloc] initByStop:self.busStopNumber];
//	}
//	return _busInfo;
//}

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

- (void)updateRouteTable{
	self.tripArray = [[GRTBusInfo getTripsByStop:self.busStopNumber] mutableCopy];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	[self updateRouteTable];
	self.navigationBar.title = [NSString stringWithFormat:@"%@", self.busStopNumber];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction) backToAddingWhenClick:(UIBarButtonItem *)sender{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table View Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.tripArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"routeCell";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = self.tableCell;
        self.tableCell = nil;
    }
	
	GRTTripEntry *entry = (GRTTripEntry *)[self.tripArray objectAtIndex:indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", entry.routeId, entry.tripHeadsign];

    return cell;
}


@end
