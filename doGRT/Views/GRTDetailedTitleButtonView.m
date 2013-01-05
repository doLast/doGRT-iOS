//
//  GRTDetailedTitleButtonView.m
//  doGRT
//
//  Created by Greg Wang on 12-12-30.
//
//

#import "GRTDetailedTitleButtonView.h"

@interface GRTDetailedTitleButtonView()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *detailTextLabel;

@end

@implementation GRTDetailedTitleButtonView

@synthesize textLabel = _textLabel;
@synthesize detailTextLabel = _detailTextLabel;

- (GRTDetailedTitleButtonView *)initWithText:(NSString *)text detailText:(NSString *)detailText
{
	CGFloat labelWidth = 180.0;
	self = [self initWithFrame:CGRectMake(0.0, 0.0, labelWidth, 32.0)];
	if (self) {
		UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 2.0, labelWidth, 16.0)];
		textLabel.textAlignment = NSTextAlignmentCenter;
		textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
		textLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
		textLabel.backgroundColor = [UIColor clearColor];
		textLabel.textColor = [UIColor whiteColor];
		textLabel.shadowColor = [UIColor darkGrayColor];
		
		UILabel *detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 18.0, labelWidth, 14.0)];
		detailTextLabel.textAlignment = NSTextAlignmentCenter;
		detailTextLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize] - 2.0];
		detailTextLabel.backgroundColor = [UIColor clearColor];
		detailTextLabel.textColor = [UIColor whiteColor];
		detailTextLabel.shadowColor = [UIColor darkGrayColor];
		
		[self addSubview:textLabel];
		[self addSubview:detailTextLabel];
		self.textLabel = textLabel;
		self.detailTextLabel = detailTextLabel;
		
		self.textLabel.text = text;
		self.detailTextLabel.text = detailText;
	}
	return self;
}

@end
