//
//  GRTStopDetailsManager.h
//  doGRT
//
//  Created by Greg Wang on 13-1-5.
//
//

#import <PopoverView.h>
@class GRTStopDetails;
@class GRTRoute;

@protocol GRTStopDetailsManagerDelegate <NSObject>

- (void)setStopTimes:(NSArray *)stopTimes splitLeftAndComingBuses:(BOOL)split;
- (UIView *)view;
- (UINavigationItem *)navigationItem;

@end

@interface GRTStopDetailsManager : NSObject <PopoverViewDelegate>

@property (nonatomic, strong) GRTStopDetails *stopDetails;
@property (nonatomic, strong) GRTRoute *route;
@property (nonatomic) NSUInteger dayInWeek;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) id<GRTStopDetailsManagerDelegate> delegate;

- (GRTStopDetailsManager *)initWithStopDetails:(GRTStopDetails *)stopDetails;
- (GRTStopDetailsManager *)initWithStopDetails:(GRTStopDetails *)stopDetails route:(GRTRoute *)route;

@end
