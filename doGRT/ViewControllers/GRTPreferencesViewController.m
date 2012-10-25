//
//  GRTPreferencesViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-10-24.
//
//

#import "GRTPreferencesViewController.h"
#import "GRTUserProfile.h"

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
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	QFloatElement *slider = (QFloatElement *) [self.root elementWithKey:@"nearbyDistanceSlider"];
	[slider addObserver:self forKeyPath:@"floatValue" options:NSKeyValueObservingOptionNew context:nil];
	[self updateNearbyDistanceLabel];
}

- (void)viewDidDisappear:(BOOL)animated
{
	QFloatElement *slider = (QFloatElement *) [self.root elementWithKey:@"nearbyDistanceSlider"];
	[slider removeObserver:self forKeyPath:@"floatValue"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[super viewDidDisappear:animated];
}

//- (void)setQuickDialogTableView:(QuickDialogTableView *)quickDialogTableView
//{
//	[super setQuickDialogTableView:quickDialogTableView];
//}

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

- (void)updateNearbyDistanceLabel
{
	QFloatElement *slider = (QFloatElement *) [self.root elementWithKey:@"nearbyDistanceSlider"];
	QLabelElement *label  = (QLabelElement *) [self.root elementWithKey:@"nearbyDistanceLabel"];
	double nearbyDistance = slider.floatValue * (GRTPreferencesMaxNearbyDistance - GRTPreferencesMinNearbyDistance) + GRTPreferencesMinNearbyDistance;
	label.value = [NSString stringWithFormat:@"%0.f", nearbyDistance];
	
	[[GRTUserProfile defaultUserProfile] setPreference:[NSNumber numberWithDouble:nearbyDistance] forKey:GRTUserNearbyDistancePreference];
	
	[self.quickDialogTableView reloadCellForElements:label, nil];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if ([keyPath isEqual:@"floatValue"]) {
		[self updateNearbyDistanceLabel];
    }
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
						   @"This is an unofficial GRT Schedule app, built by Greg Wang. \nBlog: http://blog.gregwym.info\n"];
	
    QSection *info = [[QSection alloc] init];
    [info addElement:title];
    [info addElement:intro];
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
	[rating setOnSelected:^{
		NSString* url = [NSString stringWithFormat: @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=495688038"];
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString:url]];
	}];
	QElement *feedback = [[QLabelElement alloc] initWithTitle:@"Or send me some feedback" Value:nil];
	[feedback setOnSelected:^{
		NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		NSString* url = [NSString stringWithFormat: @"mailto:dogrt@dolast.com?subject=UserFeedback&body=dogrt%@", appVersion];
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString:url]];
	}];
	
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
	
	QSection *settings = [[QSection alloc] init];
	QLabelElement *nearbyDistanceLabel = [[QLabelElement alloc] initWithTitle:@"Nearby Stops Distance (m)" Value:@"0.0"];
	nearbyDistanceLabel.key = @"nearbyDistanceLabel";
	QFloatElement *nearbyDistanceSlider = [[QFloatElement alloc] init];
	nearbyDistanceSlider.key = @"nearbyDistanceSlider";
	
	NSNumber *nearbyDistance = [[GRTUserProfile defaultUserProfile] preferenceForKey:GRTUserNearbyDistancePreference];
	nearbyDistanceSlider.floatValue = (nearbyDistance.doubleValue - GRTPreferencesMinNearbyDistance) / (GRTPreferencesMaxNearbyDistance - GRTPreferencesMinNearbyDistance);
	
	[settings addElement:nearbyDistanceLabel];
	[settings addElement:nearbyDistanceSlider];
	[root addSection:settings];
	
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
