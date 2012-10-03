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

@class GRTStop;

@interface GRTMainStopsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UISearchDisplayDelegate, GRTStopsTableViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet GRTStopsTableViewController *searchResultViewController;
//@property (nonatomic, weak) IBOutlet id<GRTStopsSearchDelegate> delegate;

- (IBAction)showPreferences:(id)sender;
- (IBAction)startTrackingUserLocation:(id)sender;
- (IBAction)didTapLeftNavButton:(id)sender;
- (IBAction)showSearch:(id)sender;
- (IBAction)didTapRightNavButton:(id)sender;

@end
