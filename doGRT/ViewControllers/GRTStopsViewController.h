//
//  GRTBusStopsViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-24.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface GRTStopsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;

- (IBAction)showSearch:(id)sender;

@end
