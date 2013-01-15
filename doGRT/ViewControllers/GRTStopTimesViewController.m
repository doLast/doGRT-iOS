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
@property (nonatomic, strong) NSTimer *comingBusIndexUpdateTimer;

@end

@implementation GRTStopTimesViewController

@synthesize tableView = _tableView;
@synthesize delegate = _delegate;
@synthesize stopTimes = _stopTimes;
@synthesize comingBusIndex = _comingBusIndex;
@synthesize comingBusIndexUpdateTimer = _comingBusIndexUpdateTimer;
@synthesize splitLeftAndComingBuses = _splitLeftAndComingBuses;

- (void)setStopTimes:(NSArray *)stopTimes
{
	if (_stopTimes != stopTimes) {
		_stopTimes = stopTimes;
	}
	
	[self.comingBusIndexUpdateTimer invalidate];
	self.comingBusIndexUpdateTimer = nil;
	[self updateComingBusIndex];
	[self scrollToAppropriateIndexAnimated:self.isViewLoaded];

	if (self.splitLeftAndComingBuses && stopTimes != nil && [stopTimes count] > 0) {
		self.comingBusIndexUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(updateComingBusIndex) userInfo:nil repeats:YES];
	}
}

- (void)setStopTimes:(NSArray *)stopTimes splitLeftAndComingBuses:(BOOL)split
{
	_splitLeftAndComingBuses = split;
	[self setStopTimes:stopTimes];
}

- (void)setComingBusIndex:(NSInteger)comingBusIndex
{
	if (comingBusIndex > [self.stopTimes count]) {
		comingBusIndex = [self.stopTimes count];
	}
	_comingBusIndex = comingBusIndex;
	
	[self.tableView reloadData];
}

//- (void)viewDidAppear:(BOOL)animated
//{
//	[super viewDidAppear:animated];
//	NSLog(@"Frame: %f, %f", self.view.frame.size.width, self.view.frame.size.height);
//	[self scrollToAppropriateIndexAnimated:YES];
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_splitLeftAndComingBuses = YES;
	
	// If self is working as a independent view controller, stopDetailsManager must be setted
	if (self.parentViewController == nil || [self.parentViewController isKindOfClass:[UINavigationController class]]) {
		NSAssert(self.stopDetailsManager != nil, @"Must have a stopTimes");
		self.stopDetailsManager.delegate = self;
	}
}

#pragma mark - view updates

- (void)updateComingBusIndex
{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:[NSDate date]];
	NSInteger curTime = comps.hour * 10000 + comps.minute * 100 + comps.second;
	NSInteger comingBusIndex = [self.stopTimes indexesOfObjectsPassingTest:^BOOL(GRTStopTime *obj, NSUInteger idx, BOOL *stop){
		if (obj.departureTime.integerValue >= curTime) {
			*stop = YES;
			return YES;
		}
		return NO;
	}].firstIndex;
	self.comingBusIndex = comingBusIndex;
}

- (void)scrollToAppropriateIndexAnimated:(BOOL)animated
{
	if (self.stopTimes == nil || [self.stopTimes count] == 0) {
		return;
	}
	
	NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
	if (self.comingBusIndex > 2){
		scrollIndexPath = [NSIndexPath indexPathForRow:self.comingBusIndex - 2 inSection:0];
	}
	else if(self.comingBusIndex > 0) {
		scrollIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	}
	
	NSLog(@"Scrolling to indexPath: %@, comingBusIndex: %d", scrollIndexPath, self.comingBusIndex);
	[self.tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionTop animated:animated];
}

- (void)showTripDetailsForStopTime:(GRTStopTime *)stopTime inNavigationController:(UINavigationController *)navigationController
{
	GRTStopsMapViewController *tripDetailsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"tripDetailsView"];
	tripDetailsVC.title = [NSString stringWithFormat:@"%@ %@", stopTime.trip.route.routeId, stopTime.trip.tripHeadsign];
	tripDetailsVC.inRegionStopsDisplayThreshold = 0.03;
	[navigationController pushViewController:tripDetailsVC animated:YES];
	
	tripDetailsVC.shape = stopTime.trip.shape;
	tripDetailsVC.stops = stopTime.trip.stopTimes;
	
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
	if (!self.splitLeftAndComingBuses) {
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger numberOfSections = [self.stopTimes count] == 0 ? 0 : self.splitLeftAndComingBuses ? 2 : 1;
	return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger result;
	if (!self.splitLeftAndComingBuses) {
		result = [self.stopTimes count];
	}
	else if (section == 0) {
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
		cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
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
	cell.detailTextLabel.textColor = (indexPath.section > 0 || !self.splitLeftAndComingBuses) ? [UIColor darkTextColor] : [UIColor lightGrayColor];
	
	NSNumber *display24Hour = [[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserDisplay24HourPreference];
	if (display24Hour.boolValue) {
		cell.textLabel.text = [NSString stringWithFormat:@"%02d:%02d", time / 10000, (time / 100) % 100 ];
	}
	else {
		cell.textLabel.text = [NSString stringWithFormat:@"%02d:%02d %@", (time / 10000) % 12, (time / 100) % 100, ((time / 10000) / 12) ? @"pm" : @"am"];
	}
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	GRTStopTime *stopTime = [self.stopTimes objectAtIndex:indexPath.row + (self.comingBusIndex * indexPath.section)];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(stopTimesViewController:didSelectStopTime:)]) {
		[self.delegate stopTimesViewController:self didSelectStopTime:stopTime];
	}
	else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[self showTripDetailsForStopTime:stopTime inNavigationController:self.navigationController];
	}
}

@end
