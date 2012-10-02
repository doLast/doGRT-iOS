//
//  GRTMainStopsViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class GRTStop;

@protocol GRTStopsSearchDelegate <NSObject>

- (void)presentStop:(GRTStop *)stop;

@end

@interface GRTMainStopsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UISearchDisplayDelegate, GRTStopsSearchDelegate>

@property (nonatomic, strong) NSArray *stops;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet GRTMainStopsViewController *searchResultViewController;
@property (nonatomic, weak) IBOutlet id<GRTStopsSearchDelegate> delegate;

- (IBAction)showPreferences:(id)sender;
- (IBAction)startTrackingUserLocation:(id)sender;
- (IBAction)didTapLeftNavButton:(id)sender;
- (IBAction)showSearch:(id)sender;
- (IBAction)didTapRightNavButton:(id)sender;

@end
