//
//  GRTStopDetailsManager.m
//  doGRT
//
//  Created by Greg Wang on 13-1-5.
//
//

#import "GRTDetailedTitleButtonView.h"

#import "GRTStopDetailsManager.h"
#import "GRTGtfsSystem.h"

@interface GRTStopDetailsManager ()

@property (nonatomic, weak) GRTDetailedTitleButtonView *stopDetailsTitleView;

@end

@implementation GRTStopDetailsManager

@synthesize stopDetails = _stopDetails;
@synthesize route = _route;
@synthesize dayInWeek = _dayInWeek;
@synthesize date = _date;
@synthesize delegate = _delegate;

@synthesize stopDetailsTitleView = _stopDetailsTitleView;

- (void)setDelegate:(id<GRTStopDetailsManagerDelegate>)delegate
{
	_delegate = delegate;
	if (delegate != nil) {
		self.stopDetailsTitleView = [self constructTitleView];
		[self updateStopTimes];
	}
}

- (void)setStopDetailsTitleView:(GRTDetailedTitleButtonView *)stopDetailsTitleView
{
	_stopDetailsTitleView = stopDetailsTitleView;
	self.delegate.navigationItem.titleView = stopDetailsTitleView;
}

#pragma mark - constructors

- (GRTStopDetailsManager *)initWithStopDetails:(GRTStopDetails *)stopDetails
{
	self = [self initWithStopDetails:stopDetails route:nil];
	return self;
}

- (GRTStopDetailsManager *)initWithStopDetails:(GRTStopDetails *)stopDetails route:(GRTRoute *)route
{
	if (stopDetails == nil) {
		return nil;
	}
	self = [super init];
	if (self != nil) {
		self.stopDetails = stopDetails;
		self.route = route;
		self.dayInWeek = 1;
		self.date = [NSDate date];
	}
	return self;
}

- (GRTDetailedTitleButtonView *)constructTitleView
{
	NSString *title = self.stopDetails.stop.stopName;
	if (self.route != nil) {
		title = [title stringByAppendingFormat:@" - %d", self.route.routeId.integerValue];
	}
	GRTDetailedTitleButtonView *titleView = [[GRTDetailedTitleButtonView alloc] initWithText:title detailText:@"Today ▾"];
	[titleView addTarget:self action:@selector(showModePicker:) forControlEvents:UIControlEventTouchUpInside];
	return titleView;
}

#pragma mark - actions

- (BOOL)isSameDayWithDate1:(NSDate*)date1 date2:(NSDate*)date2 {
	NSCalendar *calendar = [NSCalendar currentCalendar];

	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents *comp1 = [calendar components:unitFlags fromDate:date1];
	NSDateComponents *comp2 = [calendar components:unitFlags fromDate:date2];

	return [comp1 day] == [comp2 day] &&
	[comp1 month] == [comp2 month] &&
	[comp1 year] == [comp2 year];
}

- (void)updateStopTimes
{
	NSArray *stopTimes = nil;
	if (self.date == nil) {
		stopTimes = [self.stopDetails stopTimesForDayInWeek:self.dayInWeek andRoute:self.route];
		[self.delegate setStopTimes:stopTimes splitLeftAndComingBuses:NO];
	}
	else {
		stopTimes = [self.stopDetails stopTimesForDate:self.date andRoute:self.route];
		BOOL isToday = [self isSameDayWithDate1:self.date date2:[NSDate date]];
		[self.delegate setStopTimes:stopTimes splitLeftAndComingBuses:isToday];
	}
}

- (IBAction)showModePicker:(id)sender
{
	CGPoint point = CGPointMake(self.delegate.view.frame.size.width / 2.0, 0.0f);
	PopoverView *popoverView = [PopoverView showPopoverAtPoint:point inView:self.delegate.view withStringArray:[NSArray arrayWithObjects:@"Today", @"Day in a week", /*@"Certain Date", */nil] delegate:self];
	popoverView.tag = 0;
}

- (IBAction)showDayPicker:(id)sender
{
	CGPoint point = CGPointMake(self.delegate.view.frame.size.width / 2.0, 0.0f);
	PopoverView *popoverView = [PopoverView showPopoverAtPoint:point inView:self.delegate.view withTitle:@"Pick a date" withStringArray:@[@"Sunday/Holiday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"] delegate:self];
	popoverView.tag = 1;
}

- (IBAction)showDatePicker:(id)sender
{
	CGPoint point = CGPointMake(self.delegate.view.frame.size.width / 2.0, 0.0f);
	// TODO: Use Calendar Instead
	PopoverView *popoverView = [PopoverView showPopoverAtPoint:point inView:self.delegate.view withTitle:@"Pick a date" withStringArray:@[@"Sunday/Holiday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"] delegate:self];
	popoverView.tag = 2;
}

#pragma mark - popover view delegate

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
	NSUInteger tag = popoverView.tag;
	[popoverView dismiss];
	if (tag == 0) {
		switch (index) {
			case 1:
				return [self showDayPicker:self];
			case 2:
				return [self showDatePicker:self];
			default:
				self.date = [NSDate date];
				self.stopDetailsTitleView.detailTextLabel.text = @"Today ▾";
		}
	}
	else if (tag == 1) {
		self.dayInWeek = index + 1;
		self.date = nil;
		NSArray *days = @[@"Sunday/Holiday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"];
		self.stopDetailsTitleView.detailTextLabel.text = [NSString stringWithFormat:@"%@ ▾", [days objectAtIndex:index]];
	}
	// TODO: Handle other type of popovers
	
	[self updateStopTimes];
}

@end
