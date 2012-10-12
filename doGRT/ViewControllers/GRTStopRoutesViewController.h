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

@interface GRTStopRoutesViewController : UITableViewController

@property (nonatomic, weak) id<GRTStopRoutesViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *routes;

@end
