//
//  GRTStopRoutesViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

#import "GRTStopRoutesViewController.h"

#import "GRTGtfsSystem.h"

@interface GRTStopRoutesViewController ()

@end

@implementation GRTStopRoutesViewController

@synthesize delegate = _delegate;
@synthesize routes = _routes;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	NSAssert(self.routes != nil, @"Must have routes");
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.routes count];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"routeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    
    // Configure the cell...
	GRTRoute *route = [self.routes objectAtIndex:indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", route.routeId, route.routeLongName];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didSelectRoute:)]) {
		[self.delegate didSelectRoute:[self.routes objectAtIndex:indexPath.row]];
	}
}

@end
