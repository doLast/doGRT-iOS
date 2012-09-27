//
//  GRTStopRoutesViewController.h
//  doGRT
//
//  Created by Greg Wang on 12-9-27.
//
//

@class GRTRoute;

@protocol GRTStopRoutesViewControllerDelegate <NSObject>

- (void)didSelectRoute:(GRTRoute *)route;

@end

@interface GRTStopRoutesViewController : UITableViewController

@property (nonatomic, weak) id<GRTStopRoutesViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *routes;

@end
