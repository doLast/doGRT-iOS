//
//  GRTDetailedTitleButtonView.h
//  doGRT
//
//  Created by Greg Wang on 12-12-30.
//
//

@interface GRTDetailedTitleButtonView : UIButton

@property (nonatomic, strong, readonly) UILabel *textLabel;
@property (nonatomic, strong, readonly) UILabel *detailTextLabel;

- (GRTDetailedTitleButtonView *)initWithText:(NSString *)text detailText:(NSString *)detailText;

@end
