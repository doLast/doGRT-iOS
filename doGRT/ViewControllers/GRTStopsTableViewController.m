//
//  GRTStopsTableViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-10-1.
//
//

#import "GRTStopsTableViewController.h"

#import "GRTGtfsSystem.h"
#import "GRTUserProfile.h"

@interface GRTStopsTableViewController ()

@end

@implementation GRTStopsTableViewController

@synthesize delegate = _delegate;
@synthesize stops = _stops;

#pragma mark - view life-cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Table view data source

- (id<GRTStopAnnotation>)stopAtIndex:(NSUInteger)index
{
	return [self.stops objectAtIndex:index];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.stops == nil ? 0 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.stops count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id<GRTStopAnnotation> stop = [self stopAtIndex:indexPath.row];
	
    static NSString *stopCellIdentifier = @"stopCell";
	static NSString *favStopCellIdentifier = @"favStopCell";
	NSString *CellIdentifier = [stop isKindOfClass:[GRTFavoriteStop class]] ? favStopCellIdentifier : stopCellIdentifier;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if ([stop isKindOfClass:[GRTFavoriteStop class]]) {
			cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		}
	}
	
	cell.textLabel.text = stop.title;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", stop.subtitle];
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [[self stopAtIndex:indexPath.row] isKindOfClass:[GRTFavoriteStop class]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	id<GRTStopAnnotation> stop = [self stopAtIndex:indexPath.row];
	GRTFavoriteStop *favoriteStop = nil;
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		favoriteStop = [[GRTUserProfile defaultUserProfile] addStop:stop.stop];
	}
	else if (editingStyle == UITableViewCellEditingStyleDelete) {
		if ([stop isKindOfClass:[GRTFavoriteStop class]]) {
			favoriteStop = stop;
			[[GRTUserProfile defaultUserProfile] removeFavoriteStop:favoriteStop];
		}
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	id<GRTStopAnnotation> stop = [self stopAtIndex:sourceIndexPath.row];
	if (![stop isKindOfClass:[GRTFavoriteStop class]]) {
		return;
	}
	[[GRTUserProfile defaultUserProfile] moveFavoriteStop:stop toIndex:destinationIndexPath.row];
}

#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
//{
//	GRTFavoriteStop *stop = [[self stopsArrayForSection:indexPath.section] objectAtIndex:indexPath.row];
//	
//	if (self.delegate == nil && indexPath.section == GRTStopsTableFavoritesSection) {
//		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit Favorite Stop Name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
//		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
//		UITextField *textField = [alert textFieldAtIndex:0];
//
//		GRTFavoriteStop *stop = [[self stopsArrayForSection:indexPath.section] objectAtIndex:indexPath.row];
//		self.editingFavIndexPath = indexPath;
//		textField.text = stop.displayName;
//
//		[alert show];
//	}
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(tableViewController:wantToPresentStop:)]) {
		id<GRTStopAnnotation> stop = [self.stops objectAtIndex:indexPath.row];
		[self.delegate tableViewController:self wantToPresentStop:stop];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([[self stopAtIndex:indexPath.row] isKindOfClass:[GRTFavoriteStop class]]) {
		return UITableViewCellEditingStyleDelete;
	}
	else if ([[self stopAtIndex:indexPath.row] isKindOfClass:[GRTStop class]]) {
		return UITableViewCellEditingStyleInsert;
	}
	return UITableViewCellAccessoryNone;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if (proposedDestinationIndexPath.section != sourceIndexPath.section) {
		NSInteger row = (sourceIndexPath.section > proposedDestinationIndexPath.section) ?
		0 : [self.stops count] - 1;
		return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
	}
	else if (proposedDestinationIndexPath.row >= [self.stops count]) {
		return [NSIndexPath indexPathForRow:[self.stops count] - 1 inSection:sourceIndexPath.section];
	}

	return proposedDestinationIndexPath;
}

@end
