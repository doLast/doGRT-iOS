//
//  GRTStopTimesViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTStopTimesViewController.h"
#import "UINavigationController+Rotation.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopTimesViewController ()

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSArray *currentStopTimes;
@property (nonatomic, strong) GRTFavoriteStop *favoriteStop;

@end

@implementation GRTStopTimesViewController

@synthesize tableView = _tableView;

@synthesize stopTimes = _stopTimes;
@synthesize date = _date;
@synthesize currentStopTimes = _currentStopTimes;
@synthesize favoriteStop = _favoriteStop;

- (void)setDate:(NSDate *)date
{
	if (_date != nil) {
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *newComps = [calendar components:NSWeekdayCalendarUnit fromDate:date];
		NSDateComponents *oldComps = [calendar components:NSWeekdayCalendarUnit fromDate:self.date];
		
		NSUInteger newDay = newComps.weekday;
		NSUInteger oldDay = oldComps.weekday;
		
		if (newDay == oldDay) {
			return;
		}
	}
	_date = date;
	self.currentStopTimes = [self.stopTimes stopTimesForDate:_date];
	[self.tableView reloadData];
}

- (void)setFavoriteStop:(GRTFavoriteStop *)favoriteStop
{
	_favoriteStop = favoriteStop;
	// TODO: Change fav button state
	
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSAssert(self.stopTimes != nil, @"Must have a stopTimes");

	self.title = self.stopTimes.stop.stopName;
	self.date = [NSDate date];
	self.favoriteStop = [[GRTUserProfile defaultUserProfile] favoriteStopByStop:self.stopTimes.stop];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

#pragma mark - actions

- (IBAction)toggleStopFavorite:(id)sender
{
	if (self.favoriteStop != nil){
		if ([[GRTUserProfile defaultUserProfile] removeFavoriteStop:self.favoriteStop]) {
			self.favoriteStop = nil;
		}
	}
	else {
		self.favoriteStop = [[GRTUserProfile defaultUserProfile] addStop:self.stopTimes.stop];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1; // TODO: Splite left and coming buses
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.currentStopTimes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"stopTimesCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    
	GRTStopTime *stopTime = [self.currentStopTimes objectAtIndex:indexPath.row];
	NSUInteger time = [stopTime.departureTime integerValue];
	
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", stopTime.trip.route.routeId, stopTime.trip.tripHeadsign];
	cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
	cell.textLabel.textAlignment = NSTextAlignmentCenter;
	cell.textLabel.text = [NSString stringWithFormat:@"%02d:%02d", time / 10000, (time / 100) % 100 ];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
