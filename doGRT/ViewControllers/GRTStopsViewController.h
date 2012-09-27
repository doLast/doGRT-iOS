//
//  GRTStopsViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import <MapKit/MapKit.h>

@class GRTStop;

@protocol GRTStopsSearchDelegate <NSObject>

- (void)didSearchedStop:(GRTStop *)stop;

@end

@interface GRTStopsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UISearchDisplayDelegate, GRTStopsSearchDelegate>

@property (nonatomic, strong) NSArray *stops;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet GRTStopsViewController *searchResultViewController;
@property (nonatomic, weak) IBOutlet id<GRTStopsSearchDelegate> delegate;

- (IBAction)showPreferences:(id)sender;
- (IBAction)startTrackingUserLocation:(id)sender;
- (IBAction)didTapLeftNavButton:(id)sender;
- (IBAction)showSearch:(id)sender;

@end
