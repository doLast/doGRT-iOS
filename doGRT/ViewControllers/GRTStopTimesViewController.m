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

@property (nonatomic) NSInteger comingBusIndex;

@end

@implementation GRTStopTimesViewController

@synthesize delegate = _delegate;
@synthesize stopTimes = _stopTimes;
@synthesize comingBusIndex = _comingBusIndex;

- (void)setStopTimes:(NSArray *)stopTimes
{
	if (_stopTimes != stopTimes) {
		_stopTimes = stopTimes;
		
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *comps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:[NSDate date]];
		NSInteger curTime = comps.hour * 10000 + comps.minute * 100 + comps.second;
		self.comingBusIndex = [[self.stopTimes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departureTime<=%d", curTime, nil]] count];
		
		[self.tableView reloadData];
		
		if(self.comingBusIndex > 2){
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.comingBusIndex - 2 inSection:0];
			[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSAssert(self.stopTimes != nil, @"Must have stopTimes");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
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
		result = [self.stopTimes count] - self.comingBusIndex;
	}
	return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"stopTimesCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
	}
    
	GRTStopTime *stopTime = [self.stopTimes objectAtIndex:indexPath.row + (self.comingBusIndex * indexPath.section)];
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
//	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didSelectStopTime:)]) {
		[self.delegate didSelectStopTime:[self.stopTimes objectAtIndex:indexPath.row + (self.comingBusIndex * indexPath.section)]];
	}
}

@end
