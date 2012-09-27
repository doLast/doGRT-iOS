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
@property (assign, nonatomic) NSInteger comingBusIndex;
@property (nonatomic, strong) GRTFavoriteStop *favoriteStop;

@end

@implementation GRTStopTimesViewController

@synthesize tableView = _tableView;

@synthesize stopTimes = _stopTimes;
@synthesize date = _date;
@synthesize currentStopTimes = _currentStopTimes;
@synthesize comingBusIndex = _comingBusIndex;
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
}

- (void)setCurrentStopTimes:(NSArray *)currentStopTimes
{
	if (_currentStopTimes != currentStopTimes) {
		_currentStopTimes = currentStopTimes;
		
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *comps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:[NSDate date]];
		NSInteger curTime = comps.hour * 10000 + comps.minute * 100 + comps.second;
		self.comingBusIndex = [[self.currentStopTimes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departureTime<=%d", curTime, nil]] count];
		
		[self.tableView reloadData];
		
		if(self.comingBusIndex > 3){
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.comingBusIndex - 3 inSection:0];
			[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}
	}
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger result;
	if (section == 0) {
		result = self.comingBusIndex;
	}
	else {
		result = [self.currentStopTimes count] - self.comingBusIndex;
	}
	return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"stopTimesCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    
	GRTStopTime *stopTime = [self.currentStopTimes objectAtIndex:indexPath.row + (self.comingBusIndex * indexPath.section)];
	NSInteger time = [stopTime.departureTime integerValue];
	if(time >= 240000){
		time -= 240000;
	}
	else if(time < 0){
		time += 240000;
	}
	
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", stopTime.trip.route.routeId, stopTime.trip.tripHeadsign];
	if (indexPath.section == 0) {
		cell.detailTextLabel.textColor = [UIColor lightGrayColor];
	}
	else {
		cell.detailTextLabel.textColor = [UIColor darkTextColor];
	}
	
	cell.textLabel.text = [NSString stringWithFormat:@"%02d:%02d", time / 10000, (time / 100) % 100 ];
	cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
	cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}

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
