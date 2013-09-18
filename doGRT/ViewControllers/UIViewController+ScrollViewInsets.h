//
//  UIViewController+ScrollViewInsets.h
//  doGRT
//
//  Created by Greg on 2013-09-13.
//
//

@interface UIViewController (ScrollViewInsets)

- (UIEdgeInsets)insetsAvoidingBars;
- (void)adjustScrollViewInsets:(UIScrollView *)scrollView;
- (void)adjustAllScrollViewsInsets;

@end
