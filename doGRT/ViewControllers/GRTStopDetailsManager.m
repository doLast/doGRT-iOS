//
//  GRTStopDetailsManager.m
//  doGRT
//
//  Created by Greg Wang on 13-1-5.
//
//

#import "GRTDetailedTitleButtonView.h"
#import <REMenu/REMenu.h>

#import "GRTStopDetailsManager.h"
#import "GRTGtfsSystem.h"

@interface GRTStopDetailsManager ()

@property (nonatomic, weak) GRTDetailedTitleButtonView *stopDetailsTitleView;
@property (nonatomic, strong) REMenu *menu;

@end

@implementation GRTStopDetailsManager

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

- (void)setMenu:(REMenu *)menu
{
	[_menu close];
	_menu = menu;
}

#pragma mark - general helpers

- (NSString *)constructTitleDetailTextForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];

    if (![calendar isDate:date inSameDayAsDate:[NSDate date]]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMddEEEE" options:0 locale:nil];
        NSString *formattedDate = [dateFormatter stringFromDate:self.date];
        return [NSString stringWithFormat:@"%@ ▾", formattedDate];
    }
    return @"Today ▾";
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
		self.date = [NSDate date];
	}
	return self;
}

- (void)dealloc
{
	[self.menu close];
}

- (GRTDetailedTitleButtonView *)constructTitleView
{
	NSString *title = self.stopDetails.stop.stopName;
	if (self.route != nil) {
		title = [title stringByAppendingFormat:@" - %ld", (long)self.route.routeId.integerValue];
	}
    NSString *detailText = [self constructTitleDetailTextForDate:self.date];
	GRTDetailedTitleButtonView *titleView = [[GRTDetailedTitleButtonView alloc] initWithText:title detailText:detailText];

	[titleView addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
	return titleView;
}

- (REMenu *)constructMenuWithItems:(NSArray *)items
{
	REMenu *menu = [[REMenu alloc] initWithItems:items];

	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
		UIColor *lightColor = [UIColor colorWithWhite:1 alpha:0.85];
		UIColor *darkColor = [UIColor colorWithWhite:0.8 alpha:1];
		UIColor *textColor = [UIColor darkTextColor];
		UIColor *clearColor = [UIColor clearColor];

		menu.backgroundColor = lightColor;
		menu.textColor = textColor;
		menu.textShadowColor = clearColor;
		menu.separatorColor = darkColor;
		menu.borderColor = darkColor;

		menu.highlightedBackgroundColor = darkColor;
		menu.highlightedTextColor = textColor;
		menu.highlightedTextShadowColor = clearColor;
		menu.highlightedSeparatorColor = darkColor;
	}

	CGFloat borderWidth = 1.0 / [UIScreen mainScreen].scale;
	menu.separatorHeight = borderWidth;
	menu.borderWidth = borderWidth;

	menu.itemHeight = 38.0;
	menu.bounce = NO;

	menu.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
	menu.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	menu.backgroundView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];

	return menu;
}

#pragma mark - actions

- (void)updateStopTimes
{
	NSArray *stopTimes = nil;
    stopTimes = [self.stopDetails stopTimesForDate:self.date andRoute:self.route];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    BOOL isToday = [calendar isDate:self.date inSameDayAsDate:[NSDate date]];
    [self.delegate setStopTimes:stopTimes splitLeftAndComingBuses:isToday];
}

- (IBAction)toggleMenu:(id)sender
{
    if (self.menu != nil && self.menu.isOpen) {
        [self closeMenu:sender];
    } else {
        [self showModeMenu:sender];
    }
}

- (IBAction)closeMenu:(id)sender
{
	[self.menu close];
}

- (IBAction)showModeMenu:(id)sender
{
	REMenuItem *today = [[REMenuItem alloc] initWithTitle:@"Today"
												 subtitle:nil
													image:nil
										 highlightedImage:nil
												   action:^(REMenuItem *item) {
													   self.date = [NSDate date];
													   self.stopDetailsTitleView.detailTextLabel.text = @"Today ▾";
													   [self updateStopTimes];
												   }];
	REMenuItem *dayInAWeek = [[REMenuItem alloc] initWithTitle:@"Day in a week"
													  subtitle:nil
														 image:nil
											  highlightedImage:nil
														action:^(REMenuItem *item) {
															[self showDayMenu:item];
														}];

	self.menu = [self constructMenuWithItems:@[today, dayInAWeek]];
	[self.menu showFromNavigationController:self.delegate.navigationController];
}

- (IBAction)showDayMenu:(id)sender
{
	NSArray *dayNames = @[@"Sunday/Holiday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"];
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *sunday = [calendar dateBySettingUnit:NSCalendarUnitWeekday value:1 ofDate:today options:NSCalendarWrapComponents];
	NSMutableArray *items = [NSMutableArray arrayWithCapacity:[dayNames count]];
	for (NSUInteger i = 0; i < [dayNames count]; i++) {
		NSString *dayName = [dayNames objectAtIndex:i];
		REMenuItem *day = [[REMenuItem alloc] initWithTitle:dayName
												   subtitle:nil
													  image:nil
										   highlightedImage:nil
													 action:^(REMenuItem *item) {
														 self.date = [calendar dateByAddingUnit:NSCalendarUnitWeekday value:i toDate:sunday options:NSCalendarWrapComponents];
														 self.stopDetailsTitleView.detailTextLabel.text = [self constructTitleDetailTextForDate:self.date];
														 [self updateStopTimes];
													 }];
		[items addObject:day];
	}

	self.menu = [self constructMenuWithItems:items];
	[self.menu showFromNavigationController:self.delegate.navigationController];
}

@end
