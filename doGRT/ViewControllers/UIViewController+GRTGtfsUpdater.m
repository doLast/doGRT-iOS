//
//  UIViewController+GRTGtfsUpdater.m
//  doGRT
//
//  Created by Greg Wang on 12-10-14.
//
//

#import "UIViewController+GRTGtfsUpdater.h"
#import "InformaticToolbar.h"
#import "GRTGtfsSystem.h"
#import "objc/runtime.h"

static NSString * const GRTUpdateProgressBarItemSet = @"GRTUpdateProgressBarItemSet";
static BOOL silent = YES;
static id theOneRequestUpdate = nil;

@implementation UIViewController (GRTGtfsUpdater)

- (ITProgressBarItemSet *)updateProgressBarItemSet
{
	return objc_getAssociatedObject(self, (__bridge const void *)(GRTUpdateProgressBarItemSet));
}

- (void)setUpdateProgressBarItemSet:(ITProgressBarItemSet *)updateProgressBarItemSet
{
	objc_setAssociatedObject(self, (__bridge const void *)(GRTUpdateProgressBarItemSet), nil, OBJC_ASSOCIATION_RETAIN);
	objc_setAssociatedObject(self, (__bridge const void *)(GRTUpdateProgressBarItemSet), updateProgressBarItemSet, OBJC_ASSOCIATION_RETAIN);
}

- (void)becomeGtfsUpdater
{
	// Subscribe to all notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateNotification:) name:GRTGtfsDataUpdateCheckNotification object:[GRTGtfsSystem defaultGtfsSystem]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateProgressNotification:) name:GRTGtfsDataUpdateInProgressNotification object:[GRTGtfsSystem defaultGtfsSystem]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handelUpdateFinishNotification:) name:GRTGtfsDataUpdateDidFinishNotification object:[GRTGtfsSystem defaultGtfsSystem]];
}

- (void)quitGtfsUpdater
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GRTGtfsDataUpdateCheckNotification object:[GRTGtfsSystem defaultGtfsSystem]];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GRTGtfsDataUpdateInProgressNotification object:[GRTGtfsSystem defaultGtfsSystem]];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GRTGtfsDataUpdateDidFinishNotification object:[GRTGtfsSystem defaultGtfsSystem]];
}

- (void)updateGtfsUpdaterStatus
{
	[self updateToolbarToLatestStateAnimated:YES];
}

- (void)handleUpdateNotification:(NSNotification *)notification
{
	if (theOneRequestUpdate != self) {
		return;
	}
	NSNumber *dataVersion = [notification.userInfo objectForKey:GRTGtfsDataVersionKey];
	if (dataVersion != nil) {
		ITConfirmationBarItemSet *confirmationBarItemSet = [ITConfirmationBarItemSet confirmationBarItemSetWithTarget:self andConfirmAction:@selector(startUpdate:) andDismissAction:@selector(hideBarItemSet:)];
		confirmationBarItemSet.textLabel.text = @"Schedule Update Available";
		confirmationBarItemSet.detailTextLabel.text = @"It's about 20 MB. Download now?";
		[self pushBarItemSet:confirmationBarItemSet animated:YES];
	}
	else if (!silent) {
		NSLog(@"No update, but it is not silent");
		ITLabelBarItemSet *noUpdateBarItemSet = [ITLabelBarItemSet labelBarItemSetWithDismissTarget:self andAction:@selector(hideBarItemSet:)];
		noUpdateBarItemSet.textLabel.text = @"No Update Available for Now";
		noUpdateBarItemSet.detailTextLabel.text = @"Come back later.";
		[self pushBarItemSet:noUpdateBarItemSet animated:YES];
	}
}

- (void)handleUpdateProgressNotification:(NSNotification *)notification
{
	NSNumber *p = [notification.userInfo objectForKey:@"progress"];
	if (self.updateProgressBarItemSet == nil) {
		self.updateProgressBarItemSet = [ITProgressBarItemSet progressBarItemSetWithTitle:@"Downloading New Schedule..." dismissTarget:self andAction:@selector(abortUpdate:)];
	}
	if (![self.barItemSets containsObject:self.updateProgressBarItemSet]) {
		[self pushBarItemSet:self.updateProgressBarItemSet animated:YES];
	}
	[self.updateProgressBarItemSet setProgress:p.floatValue animated:YES];
}

- (void)handelUpdateFinishNotification:(NSNotification *)notification
{
	ITBarItemSet *updateProgressBarItemSet = self.updateProgressBarItemSet;
	self.updateProgressBarItemSet = nil;
	[self hideBarItemSet:updateProgressBarItemSet];
	theOneRequestUpdate = nil;
	
	NSNumber *cancelled = [notification.userInfo objectForKey:@"cancelled"];
	if (cancelled != nil && cancelled.boolValue) {
		return;
	}
	
	ITLabelBarItemSet *labelBarItemSet = nil;
	NSNumber *result = [notification.userInfo objectForKey:@"result"];
	if (result != nil && result.boolValue) {
		NSNumber *dataVersion = [[NSUserDefaults standardUserDefaults] objectForKey:GRTGtfsDataVersionKey];
		NSInteger date = dataVersion.integerValue;
		labelBarItemSet = [ITLabelBarItemSet labelBarItemSetWithDismissTarget:self andAction:@selector(hideBarItemSet:)];
		labelBarItemSet.textLabel.text = @"Update Succeed!";
		labelBarItemSet.detailTextLabel.text = [NSString stringWithFormat:@"New schedule valie until %d/%d/%d", (date / 100) % 100, date % 100, date / 10000];
	}
	else {
		labelBarItemSet = [ITConfirmationBarItemSet confirmationBarItemSetWithTarget:self andConfirmAction:@selector(startUpdate:) andDismissAction:@selector(hideBarItemSet:)];
		labelBarItemSet.textLabel.text = @"Fail to Download Update";
		labelBarItemSet.detailTextLabel.text = @"Do you want to try again?";
	}
	[self pushBarItemSet:labelBarItemSet animated:YES];
}

#pragma mark - actions

- (IBAction)checkForUpdate:(id)sender
{
	silent = sender == self;
	theOneRequestUpdate = self;
	[[GRTGtfsSystem defaultGtfsSystem] checkForUpdate];
}

- (IBAction)hideBarItemSet:(id)sender
{
	[self removeBarItemSet:sender animated:YES];
}

- (IBAction)startUpdate:(id)sender
{
	[self hideBarItemSet:sender];
	[[GRTGtfsSystem defaultGtfsSystem] startUpdate];
}

- (IBAction)abortUpdate:(id)sender
{
	[[GRTGtfsSystem defaultGtfsSystem] abortUpdate];
}

@end
