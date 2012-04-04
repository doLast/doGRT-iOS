//
//  GRTFlipsideViewController.m
//  doGRT
//
//  Created by Greg Wang on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GRTStopListViewController.h"
#import "GRTMainViewController.h"
#import "UserChosenBusStop.h"

@interface GRTStopListViewController ()
@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (retain, nonatomic) NSMutableArray *busStopArray;
@property (retain, nonatomic) NSNumber *chosenIndex;
@end

@implementation GRTStopListViewController

@synthesize busStopCell = _busStopCell;
@synthesize helpMessage = _helpMessage;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize busStopArray = _busStopArray;
@synthesize chosenIndex = _chosenIndex;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated{
	[super setEditing:editing animated:animated];
	if(editing){
		self.helpMessage.text = @"Select a bus stop to edit its name";
	}
	else {
		self.helpMessage.text = @"Press + to add a new bus stop";
	}
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.title = @"Bus Stops";
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	self.managedObjectContext = [(id) [[UIApplication sharedApplication] delegate]managedObjectContext];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"UserChosenBusStop" 
											  inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"addTime" 
																   ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	NSMutableArray *mutableFetchResults = 
	[[self.managedObjectContext executeFetchRequest:request error:nil] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
	}
	
	self.busStopArray = mutableFetchResults;
	
	self.helpMessage.text = @"Press + to add a stop";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES; // (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions


#pragma mark - Table View Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.busStopArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"busStopCell";
	
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = self.busStopCell;
        self.busStopCell = nil;
    }
	
    UserChosenBusStop *busStop = (UserChosenBusStop *)[self.busStopArray objectAtIndex:indexPath.row];
	
    cell.textLabel.text = [NSString stringWithString:busStop.stopName];
	
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [busStop.stopId integerValue]];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView 
		commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
		forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
        // Delete the managed object at the given index path.
        UserChosenBusStop *busStop = [self.busStopArray objectAtIndex:indexPath.row];
        [self.managedObjectContext deleteObject:busStop];
		
        // Update the array and table view.
        [self.busStopArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
						 withRowAnimation:YES];
		
        // Commit the change.
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            // Handle the error.
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	self.chosenIndex = [NSNumber numberWithInteger:indexPath.row];
	if(self.editing){
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit Stop Name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		UITextField *textField = [alert textFieldAtIndex:0];
		
		UserChosenBusStop *busStop = (UserChosenBusStop *) [self.busStopArray objectAtIndex:[self.chosenIndex unsignedIntegerValue]];
		textField.text = busStop.stopName;
		
		[alert show];
	}
	else {
		[self performSegueWithIdentifier:@"showMain" sender:tableView];
	}
	
	return indexPath;
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
		UITextField *textField = [alertView textFieldAtIndex:0];
		UserChosenBusStop *busStop = (UserChosenBusStop *) [self.busStopArray objectAtIndex:[self.chosenIndex unsignedIntegerValue]];
		if(textField.text.length > 0) {
			busStop.stopName = textField.text;
		
			if (![self.managedObjectContext save:nil]) {
				// Handle the error.
			}
		}
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
		[self.tableView reloadData];
    }
}

#pragma mark - Adding View

- (void)addingViewControllerDidFinishWithBusStopNumber:(NSNumber *)busStopNumber
									   withBusStopName:(NSString *)busStopName{
	if(busStopNumber){
		
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"stopId=%@", busStopNumber];
		NSArray *result = [self.busStopArray filteredArrayUsingPredicate:pred];
		if([result count] > 0){
			[self dismissModalViewControllerAnimated:YES];
			return;
		}
		
		// Create and configure a new instance of the Event entity.
		UserChosenBusStop *busStop = 
			(UserChosenBusStop *)[NSEntityDescription 
								  insertNewObjectForEntityForName:@"UserChosenBusStop" 
								  inManagedObjectContext:self.managedObjectContext];
		
		busStop.stopId = busStopNumber;
		busStop.stopName = busStopName;
		busStop.addTime = [NSDate date];
		
		NSError *error = nil;
		if (![self.managedObjectContext save:&error]) {
			// Handle the error.
		}
		
		[self.busStopArray insertObject:busStop atIndex:[self.busStopArray count]];
		[self.tableView reloadData];
	}
	else {
		// nil
	}
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Segue setting

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAdding"]) {
        [[segue destinationViewController] setDelegate:self];
    }
	else if([[segue identifier] isEqualToString:@"showMain"]) {
		GRTMainViewController *vc = (GRTMainViewController *)[segue destinationViewController];
		assert([vc isKindOfClass:[GRTMainViewController class]]);
		UserChosenBusStop *busStop = (UserChosenBusStop *) [self.busStopArray objectAtIndex:[self.chosenIndex unsignedIntegerValue]];
		
		vc.busStopNumber = busStop.stopId;
		vc.busStopName = busStop.stopName;
	}
}

@end
