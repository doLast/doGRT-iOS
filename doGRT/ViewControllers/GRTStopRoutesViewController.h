//
//  GRTStopRoutesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

@class GRTRoute;
@class GRTStopRoutesViewController;

@protocol GRTStopRoutesViewControllerDelegate <NSObject>

- (void)stopRoutesViewController:(GRTStopRoutesViewController *)stopRoutesViewController didSelectRoute:(GRTRoute *)route;

@end

@interface GRTStopRoutesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet id<GRTStopRoutesViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *routes;

@end
