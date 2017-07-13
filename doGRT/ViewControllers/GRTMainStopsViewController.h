//
//  GRTMainStopsViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "GRTStopsTableViewController.h"
#import "GRTStopsMapViewController.h"

@class GRTStop;

@interface GRTMainStopsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating, GRTStopsTableViewControllerDelegate, GRTStopsMapViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet GRTStopsTableViewController *searchResultViewController;
@property (nonatomic, strong) IBOutlet GRTStopsMapViewController *stopsMapViewController;

- (IBAction)showPreferences:(id)sender;

@end
