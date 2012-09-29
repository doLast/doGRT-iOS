//
//  GRTService.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

@interface GRTService : NSObject

@property (nonatomic, strong, readonly) NSString *serviceId;
@property (nonatomic, strong, readonly) NSNumber *startDate;
@property (nonatomic, strong, readonly) NSNumber *endDate;
@property (nonatomic, readonly) BOOL sunday;
@property (nonatomic, readonly) BOOL monday;
@property (nonatomic, readonly) BOOL tuesday;
@property (nonatomic, readonly) BOOL wednesday;
@property (nonatomic, readonly) BOOL thursday;
@property (nonatomic, readonly) BOOL friday;
@property (nonatomic, readonly) BOOL saturday;

- (GRTService *)initWithServiceId:(NSString *)serviceId startDate:(NSNumber *)startDate endDate:(NSNumber *)endDate serviceDays:(NSSet *)serviceDays;

@end
