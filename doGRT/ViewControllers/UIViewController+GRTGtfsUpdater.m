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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpdateNotification) name:kGRTGtfsDataUpdateAvailable object:[GRTGtfsSystem defaultGtfsSystem]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateProgressNotification:) name:kGRTGtfsDataUpdateInProgress object:[GRTGtfsSystem defaultGtfsSystem]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handelUpdateFinishNotification:) name:kGRTGtfsDataUpdateDidFinish object:[GRTGtfsSystem defaultGtfsSystem]];
	
	// Check for update
	[[GRTGtfsSystem defaultGtfsSystem] checkForUpdate];
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
		updateProgressBarItemSet = [ITProgressBarItemSet progressBarItemSetWithTitle:@"Downloading New Schedule..." dismissTarget:self andAction:@selector(hideBarItemSet:)];
	}
	if (![self.barItemSets containsObject:updateProgressBarItemSet]) {
		[self pushBarItemSet:updateProgressBarItemSet animated:YES];
	}
	[updateProgressBarItemSet setProgress:p.floatValue animated:YES];
}

- (void)handelUpdateFinishNotification:(NSNotification *)notification
{
	
}

#pragma mark - actions

- (IBAction)hideBarItemSet:(ITBarItemSet *)sender
{
	if (sender == updateProgressBarItemSet) {
		[[GRTGtfsSystem defaultGtfsSystem] abortUpdate];
	}
	[self removeBarItemSet:sender animated:YES];
}

- (IBAction)startUpdate:(ITBarItemSet *)sender
{
	[self removeBarItemSet:sender animated:YES];
	[[GRTGtfsSystem defaultGtfsSystem] startUpdate];
}

@end
