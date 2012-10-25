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

static ITProgressBarItemSet *updateProgressBarItemSet = nil;

@implementation UIViewController (GRTGtfsUpdater)

- (void)becomeGtfsUpdater
{
	// Subscribe to all notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdateNotification) name:GRTGtfsDataUpdateAvailableNotification object:[GRTGtfsSystem defaultGtfsSystem]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateProgressNotification:) name:GRTGtfsDataUpdateInProgressNotification object:[GRTGtfsSystem defaultGtfsSystem]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handelUpdateFinishNotification:) name:GRTGtfsDataUpdateDidFinishNotification object:[GRTGtfsSystem defaultGtfsSystem]];
	
	// Check for update
	[[GRTGtfsSystem defaultGtfsSystem] checkForUpdate];
}

- (void)updateGtfsUpdaterStatus
{
	[self updateToolbarToLatestStateAnimated:YES];
}

- (void)showUpdateNotification
{
	ITConfirmationBarItemSet *confirmationBarItemSet = [ITConfirmationBarItemSet confirmationBarItemSetWithTarget:self andConfirmAction:@selector(startUpdate:) andDismissAction:@selector(hideBarItemSet:)];
	confirmationBarItemSet.textLabel.text = @"Schedule Update Available";
	confirmationBarItemSet.detailTextLabel.text = @"Do you want to update now?";
	[self pushBarItemSet:confirmationBarItemSet animated:YES];
}

- (void)handleUpdateProgressNotification:(NSNotification *)notification
{
	NSNumber *p = [notification.userInfo objectForKey:@"progress"];
	if (updateProgressBarItemSet == nil) {
		updateProgressBarItemSet = [ITProgressBarItemSet progressBarItemSetWithTitle:@"Downloading New Schedule..." dismissTarget:self andAction:@selector(tryAbortUpdate:)];
	}
	if (![self.barItemSets containsObject:updateProgressBarItemSet]) {
		[self pushBarItemSet:updateProgressBarItemSet animated:YES];
	}
	[updateProgressBarItemSet setProgress:p.floatValue animated:YES];
}

- (void)handelUpdateFinishNotification:(NSNotification *)notification
{
	updateProgressBarItemSet = nil;
	[self removeAllBarItemSetsAnimated:YES];
	
	ITLabelBarItemSet *labelBarItemSet = nil;
	NSNumber *result = [notification.userInfo objectForKey:@"result"];
	if (result.boolValue) {
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

- (IBAction)hideBarItemSet:(ITBarItemSet *)sender
{
	[self removeBarItemSet:sender animated:YES];
}

- (IBAction)startUpdate:(ITBarItemSet *)sender
{
	[self hideBarItemSet:sender];
	[[GRTGtfsSystem defaultGtfsSystem] startUpdate];
}

- (IBAction)tryAbortUpdate:(id)sender
{
	ITConfirmationBarItemSet *confirmAbort = [ITConfirmationBarItemSet confirmationBarItemSetWithTarget:self andConfirmAction:@selector(confirmAbortUpdate:) andDismissAction:@selector(hideBarItemSet:)];
	confirmAbort.textLabel.text = @"Cancel Schedule Update";
	confirmAbort.detailTextLabel.text = @"You sure you want to cancel?";
	[self pushBarItemSet:confirmAbort animated:YES];
}

- (IBAction)confirmAbortUpdate:(id)sender
{
	updateProgressBarItemSet = nil;
	
	[[GRTGtfsSystem defaultGtfsSystem] abortUpdate];
	[self removeAllBarItemSetsAnimated:YES];
}

@end
