//
//  GRTService.m
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import "GRTService.h"

@interface GRTService ()

@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic, strong) NSNumber *startDate;
@property (nonatomic, strong) NSNumber *endDate;
@property (nonatomic, strong) NSSet *serviceDays;

@end

@implementation GRTService

@synthesize serviceId = _serviceId;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize serviceDays = _serviceDays;

- (BOOL)sunday
{
	return [self.serviceDays containsObject:@"sunday"];
}

- (BOOL)monday
{
	return [self.serviceDays containsObject:@"monday"];
}

- (BOOL)tuesday
{
	return [self.serviceDays containsObject:@"tuesday"];
}

- (BOOL)wednesday
{
	return [self.serviceDays containsObject:@"wednesday"];
}

- (BOOL)thursday
{
	return [self.serviceDays containsObject:@"thursday"];
}

- (BOOL)friday
{
	return [self.serviceDays containsObject:@"friday"];
}

- (BOOL)saturday
{
	return [self.serviceDays containsObject:@"saturday"];
}

- (GRTService *)initWithServiceId:(NSString *)serviceId startDate:(NSNumber *)startDate endDate:(NSNumber *)endDate serviceDays:(NSSet *)serviceDays
{
	self = [super init];
	if (self != nil) {
		self.serviceId = serviceId;
		self.startDate = startDate;
		self.endDate = endDate;
		self.serviceDays = serviceDays;
	}
	return self;
}

@end
