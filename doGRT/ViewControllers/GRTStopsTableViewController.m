//
//  GRTStopsTableViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-10-1.
//
//

#import "GRTStopsTableViewController.h"
#import "GRTStopDetailsViewController.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopsTableViewController ()

@end

@implementation GRTStopsTableViewController

@synthesize stops = _stops;

#pragma mark - view life-cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	NSArray *newStops = [[GRTUserProfile defaultUserProfile] allFavoriteStops];
	self.stops = newStops;
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)pushStopDetailsForStop:(GRTStop *)stop
{
	GRTStopTimes *stopTimes = [[GRTStopTimes alloc] initWithStop:stop];
	GRTStopDetailsViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"stopDetailsView"];
	viewController.stopTimes = stopTimes;
	[self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.stops == nil ? 0 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.stops count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"stopCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	id<GRTStopAnnotation> stop = [self.stops objectAtIndex:indexPath.row];
	
	cell.textLabel.text = stop.title;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", stop.subtitle];
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<GRTStopAnnotation> stop = [self.stops objectAtIndex:indexPath.row];
	[self pushStopDetailsForStop:stop.stop];
}

@end
