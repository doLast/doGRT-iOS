//
//  GRTStopTimesViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTStopTimesViewController.h"
#import "GRTStopsMapViewController.h"

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
		self.comingBusIndex = [self.stopTimes indexesOfObjectsPassingTest:^BOOL(GRTStopTime *obj, NSUInteger idx, BOOL *stop){
			if (obj.departureTime.integerValue >= curTime) {
				*stop = YES;
				return YES;
			}
			return NO;
		}].firstIndex;
		
		[self.tableView reloadData];
		
		NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:[self.stopTimes count] inSection:0];
		if (self.comingBusIndex != NSNotFound){
			scrollIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
		}
		if (self.comingBusIndex >= 2){
			scrollIndexPath = [NSIndexPath indexPathForRow:self.comingBusIndex - 2 inSection:0];
		}
		[self.tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSAssert(self.stopTimes != nil, @"Must have stopTimes");
}

- (void)showTripDetailsForStopTime:(GRTStopTime *)stopTime inNavigationController:(UINavigationController *)navigationController
{
	GRTStopsMapViewController *tripDetailsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"tripDetailsView"];
	tripDetailsVC.title = [NSString stringWithFormat:@"%@ %@", stopTime.trip.route.routeId, stopTime.trip.tripHeadsign];
	tripDetailsVC.inRegionStopsDisplayThreshold = 0.03;
	[navigationController pushViewController:tripDetailsVC animated:YES];
	
	tripDetailsVC.shape = stopTime.trip.shape;
	tripDetailsVC.stops = [[GRTGtfsSystem defaultGtfsSystem] stopTimesForTrip:stopTime.trip];
	
	NSUInteger stopTimeIndex = [tripDetailsVC.stops indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
		GRTStopTime *stopTimeObj = obj;
		if (stopTimeObj.stopSequence.integerValue == stopTime.stopSequence.integerValue) {
			*stop = YES;
			return YES;
		}
		return NO;
	}].firstIndex;
	[tripDetailsVC selectStop:[tripDetailsVC.stops objectAtIndex:stopTimeIndex]];
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
		cell.textLabel.font = [UIFont boldSystemFontOfSize:21];
		cell.textLabel.textAlignment = NSTextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
	cell.detailTextLabel.textColor = indexPath.section == 0 ? [UIColor lightGrayColor] : [UIColor darkTextColor];
	
	cell.textLabel.text = [NSString stringWithFormat:@"%02d:%02d", time / 10000, (time / 100) % 100 ];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	GRTStopTime *stopTime = [self.stopTimes objectAtIndex:indexPath.row + (self.comingBusIndex * indexPath.section)];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(stopTimesViewController:didSelectStopTime:)]) {
		[self.delegate stopTimesViewController:self didSelectStopTime:stopTime];
	}
	else if (self.navigationController != nil) {
		[self showTripDetailsForStopTime:stopTime inNavigationController:self.navigationController];
	}
}

@end
