//
//  UIViewController+ScrollViewInsets.m
//  doGRT
//
//  Created by Greg on 2013-09-13.
//
//

#import "UIViewController+ScrollViewInsets.h"

@implementation UIViewController (ScrollViewInsets)

- (UIEdgeInsets)insetsAvoidingBars
{
	if (SYSTEM_VERSION_LESS_THAN(@"7.0") || self.edgesForExtendedLayout == UIRectEdgeAll) {
		return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
	}

	CGFloat topInset = 0, bottomInset = 0;
	if (self.navigationController != nil) {
		if (self.edgesForExtendedLayout & UIRectEdgeTop && self.navigationController.navigationBar != nil) {
			topInset =
			self.navigationController.navigationBar.frame.origin.y +
			self.navigationController.navigationBar.frame.size.height;
		}
		if (self.edgesForExtendedLayout & UIRectEdgeBottom && self.navigationController.toolbar != nil) {
			bottomInset = self.navigationController.toolbar.frame.size.height;
		}
	}

	UIEdgeInsets insets = UIEdgeInsetsMake(topInset, 0.0, bottomInset, 0.0);
	return insets;
}

- (void)scrollView:(UIScrollView *)scrollView setInsets:(UIEdgeInsets)insets
{
	scrollView.contentInset = insets;
	scrollView.scrollIndicatorInsets = insets;
}

- (void)adjustScrollViewInsets:(UIScrollView *)scrollView
{
	[self scrollView:scrollView setInsets:self.insetsAvoidingBars];
}

- (void)adjustAllScrollViewsInsets
{
	UIEdgeInsets insets = self.insetsAvoidingBars;
	for (UIView *view in self.view.subviews) {
		if ([view isKindOfClass:[UIScrollView class]]) {
			[self scrollView:(UIScrollView *)view setInsets:insets];
		}
	}
}

@end
