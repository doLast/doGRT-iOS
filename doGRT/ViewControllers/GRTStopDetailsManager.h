//
//  GRTStopDetailsManager.h
//  doGRT
//
//  Created by Greg Wang on 13-1-5.
//
//

@class GRTStopDetails;
@class GRTRoute;

@protocol GRTStopDetailsManagerDelegate <NSObject>

- (void)setStopTimes:(NSArray *)stopTimes splitLeftAndComingBuses:(BOOL)split;
- (UINavigationItem *)navigationItem;
- (UINavigationController *)navigationController;

@end

@interface GRTStopDetailsManager : NSObject

@property (nonatomic, strong) GRTStopDetails *stopDetails;
@property (nonatomic, strong) GRTRoute *route;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) id<GRTStopDetailsManagerDelegate> delegate;

- (GRTStopDetailsManager *)initWithStopDetails:(GRTStopDetails *)stopDetails;
- (GRTStopDetailsManager *)initWithStopDetails:(GRTStopDetails *)stopDetails route:(GRTRoute *)route;

- (IBAction)closeMenu:(id)sender;
- (IBAction)showModeMenu:(id)sender;
- (IBAction)showDayMenu:(id)sender;

@end
