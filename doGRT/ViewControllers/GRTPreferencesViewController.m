//
//  GRTPreferencesViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-10-24.
//
//

#import "GRTPreferencesViewController.h"
#import "UIViewController+GRTGtfsUpdater.h"

#import "GRTUserProfile.h"
#import "GRTGtfsSystem.h"

static UIPopoverController *popoverController = nil;
static double GRTPreferencesMinNearbyDistance = 200.0;
static double GRTPreferencesMaxNearbyDistance = 2000.0;

@interface GRTPreferencesViewController ()

@end

@implementation GRTPreferencesViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UIBarButtonItem *hideButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	self.navigationItem.rightBarButtonItem = hideButton;
	
	[self becomeGtfsUpdater];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	QFloatElement *slider = (QFloatElement *) [self.root elementWithKey:@"nearbyDistanceSlider"];
	[slider addObserver:self forKeyPath:@"floatValue" options:NSKeyValueObservingOptionNew context:nil];
	[self updateNearbyDistanceLabel:self];
	
	[self updateGtfsUpdaterStatus];
}

- (void)viewDidDisappear:(BOOL)animated
{
	QFloatElement *slider = (QFloatElement *) [self.root elementWithKey:@"nearbyDistanceSlider"];
	double nearbyDistance = slider.floatValue;
	[[GRTUserProfile defaultUserProfile] setPreference:[NSNumber numberWithDouble:nearbyDistance] forKey:GRTUserNearbyDistancePreference];
	[slider removeObserver:self forKeyPath:@"floatValue"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
	[self quitGtfsUpdater];
	[super viewDidUnload];
}

- (void)cell:(UITableViewCell *)cell willAppearForElement:(QElement *)element atIndexPath:(NSIndexPath *)indexPath
{
	return;
}

- (IBAction)done:(id)sender
{
	if (popoverController != nil) {
		[popoverController dismissPopoverAnimated:YES];
	}
	else {
		[self dismissModalViewControllerAnimated:YES];
	}
}

- (IBAction)redirectToRatingPage:(id)sender
{
	// added work arround for wrong URL Scheme & iOS 6
	NSString *reviewURL;
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
		reviewURL = @"itms-apps://itunes.apple.com/en/app/id495688038";
		//			reviewURL = [reviewURL stringByReplacingOccurrencesOfString:@"LANGUAGE" withString:[NSString stringWithFormat:@"%@", [[NSLocale preferredLanguages] objectAtIndex:0]]];
	} else {
		reviewURL = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=495688038";
	}
	[[UIApplication sharedApplication] openURL: [NSURL URLWithString:reviewURL]];
}

- (IBAction)updateNearbyDistanceLabel:(id)sender
{
	QFloatElement *slider = (QFloatElement *) [self.root elementWithKey:@"nearbyDistanceSlider"];
	QLabelElement *label  = (QLabelElement *) [self.root elementWithKey:@"nearbyDistanceLabel"];
	double nearbyDistance = slider.floatValue;
	label.value = [NSString stringWithFormat:@"%0.f", nearbyDistance];
	
	[self.quickDialogTableView reloadCellForElements:label, nil];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if ([keyPath isEqual:@"floatValue"]) {
		[self updateNearbyDistanceLabel:object];
    }
}

#pragma mark - feedback mail composer

-(IBAction)displayComposerSheet:(id)sender
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
	
	NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [picker setSubject:[NSString stringWithFormat:@"doGRT %@ User Feedback", appVersion]];
	
    // Set up the recipients.
    NSArray *toRecipients = [NSArray arrayWithObjects:@"dogrt@dolast.com",
							 nil];
    [picker setToRecipients:toRecipients];
	
    // Fill out the email body text.
    NSString *emailBody = @"If it is a bug, please attached a screenshot. Thank you. ";
    [picker setMessageBody:emailBody isHTML:NO];
	
    // Present the mail composition interface.
    [self presentModalViewController:picker animated:YES];
}

// The mail compose view controller delegate method
- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - element builder

+ (QRootElement *)createAboutElements {
    QRootElement *root = [[QRootElement alloc] init];
    root.title = @"About This App";
	root.grouped = YES;
	root.controllerName = @"";
	
	NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    QTextElement *title = [[QTextElement alloc] initWithText:
						   [NSString stringWithFormat:@"%@ %@", @"doGRT", appVersion]];
	title.font = [UIFont boldSystemFontOfSize:24];
	
    QTextElement *intro = [[QTextElement alloc] initWithText:
						   @"This is an unofficial GRT Schedule app. \n© Greg@doLast.com"];
	QTextElement *webs = [[QTextElement alloc] initWithText:@"Web: http://dolast.com\nBlog: http://blog.gregwym.info\nTwitter: @gregwym"];
	QTextElement *thanks = [[QTextElement alloc] initWithText:
						   @"You are the one who motivate me to make this app better and better, thanks. "];
	
    QSection *info = [[QSection alloc] init];
    [info addElement:title];
    [info addElement:intro];
	[info addElement:webs];
	[info addElement:thanks];
	[root addSection:info];
	
	QTextElement *fmdb = [[QTextElement alloc] initWithText:@"fmdb: \nhttps://github.com/ccgus/fmdb"];
	QTextElement *asiHttpRequest = [[QTextElement alloc] initWithText:@"asi-http-request: \nhttps://github.com/pokeb/asi-http-request"];
	QTextElement *informaticToolbar = [[QTextElement alloc] initWithText:@"InformaticToolbar: \nhttps://github.com/gregwym/InformaticToolbar"];
	QTextElement *quickDialog = [[QTextElement alloc] initWithText:@"QuickDialog: \nhttps://github.com/escoz/quickdialog"];
	
	QSection *credit = [[QSection alloc] initWithTitle:@"Open Source Credits"];
	[credit addElement:fmdb];
	[credit addElement:asiHttpRequest];
	[credit addElement:informaticToolbar];
	[credit addElement:quickDialog];
	[root addSection:credit];
	
    return root;
}

+ (QSection *)createAboutSection
{
	QSection *section = [[QSection alloc] init];
	
	QElement *rating = [[QLabelElement alloc] initWithTitle:@"If you like this app, rate for it ^^" Value:nil];
	[rating setControllerAction:@"redirectToRatingPage:"];
	QElement *feedback = [[QLabelElement alloc] initWithTitle:@"Or send me some feedback" Value:nil];
	[feedback setControllerAction:@"displayComposerSheet:"];
	
	[section addElement:rating];
	[section addElement:feedback];
	[section addElement:[GRTPreferencesViewController createAboutElements]];
	
	return section;
}

+ (QRootElement *)createElements
{
	QRootElement *root = [[QRootElement alloc] init];
	root.title = @"Preferences";
	root.controllerName = @"GRTPreferencesViewController";
	root.grouped = YES;
	
	// Nearby distance section
	NSNumber *nearbyDistance = [[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserNearbyDistancePreference];
	QLabelElement *nearbyDistanceLabel = [[QLabelElement alloc] initWithTitle:@"Nearby Stops Distance (m)" Value:nearbyDistance.stringValue];
	nearbyDistanceLabel.key = @"nearbyDistanceLabel";
	QFloatElement *nearbyDistanceSlider = [[QFloatElement alloc] init];
	nearbyDistanceSlider.key = @"nearbyDistanceSlider";
	nearbyDistanceSlider.floatValue = nearbyDistance.doubleValue;
	nearbyDistanceSlider.maximumValue = GRTPreferencesMaxNearbyDistance;
	nearbyDistanceSlider.minimumValue = GRTPreferencesMinNearbyDistance;
	
	QSection *nearbyDistanceSection = [[QSection alloc] init];
	[nearbyDistanceSection addElement:nearbyDistanceLabel];
	[nearbyDistanceSection addElement:nearbyDistanceSlider];
	[root addSection:nearbyDistanceSection];
	
	// Default schedule view section
	NSNumber *defaultScheduleView = [[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserDefaultScheduleViewPreference];
	QRadioSection *defaultScheduleViewSection = [[QRadioSection alloc] initWithItems:@[@"Mixed Schedule", @"Routes List"] selected:defaultScheduleView.integerValue title:@"Default Schedule View"];
	__weak QRadioSection *defaultScheduleViewSectionWeak = defaultScheduleViewSection;
	[defaultScheduleViewSection setOnSelected:^{
		[[GRTUserProfile defaultUserProfile] setPreference:[defaultScheduleViewSectionWeak.selectedIndexes objectAtIndex:0] forKey:GRTUserDefaultScheduleViewPreference];
	}];
	[root addSection:defaultScheduleViewSection];
	
	// Display 24 hour view section
	NSNumber *display24Hour = [[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserDisplay24HourPreference];
	QBooleanElement *display24HourToggle = [[QBooleanElement alloc] initWithTitle:@"Show Time as 24 Hour" BoolValue:display24Hour.boolValue];
	__weak QBooleanElement *display24HourToggleWeak = display24HourToggle;
	[display24HourToggle setOnValueChanged:^(QRootElement *root){
		[[GRTUserProfile defaultUserProfile] setPreference:[NSNumber numberWithBool:display24HourToggleWeak.boolValue] forKey:GRTUserDisplay24HourPreference];
	}];
	QSection *display24HourSection = [[QSection alloc] init];
	[display24HourSection addElement:display24HourToggle];
	[root addSection:display24HourSection];
	
	// Data update
	QSection *dataUpdateSection = [[QSection alloc] initWithTitle:@"Schedule Data Update"];
	NSNumber *endDate = [[NSUserDefaults standardUserDefaults] objectForKey:GRTGtfsDataEndDateKey];
	NSInteger date = endDate.integerValue;
	dataUpdateSection.footer = [NSString stringWithFormat:@"Current schedule valid until %d/%d/%d", (date / 100) % 100, date % 100, date / 10000];
	QButtonElement *checkUpdate = [[QButtonElement alloc] initWithTitle:@"Check for update now"];
	[checkUpdate setControllerAction:@"checkForUpdate:"];
	[dataUpdateSection addElement:checkUpdate];
	[root addSection:dataUpdateSection];
	
	// About Section
	[root addSection:[GRTPreferencesViewController createAboutSection]];
	
	return root;
}

#pragma mark - constructor

+ (void)showPreferencesInViewController:(UIViewController *)viewController
{
	QRootElement *root = [GRTPreferencesViewController createElements];
	UINavigationController *preferences = [QuickDialogController controllerWithNavigationForRoot:root];
	[viewController presentModalViewController:preferences animated:YES];
}

+ (void)showPreferencesFromBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	if (popoverController == nil) {
		QRootElement *root = [GRTPreferencesViewController createElements];
		UINavigationController *preferences = [QuickDialogController controllerWithNavigationForRoot:root];
		popoverController = [[UIPopoverController alloc] initWithContentViewController:preferences];
	}
	[popoverController presentPopoverFromBarButtonItem:barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
