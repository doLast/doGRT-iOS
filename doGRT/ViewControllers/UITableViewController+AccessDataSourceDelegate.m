//
//  UITableViewController+AccessDataSourceDelegate.m
//  doGRT
//
//  Created by Greg Wang on 12-10-2.
//
//

#import "UITableViewController+AccessDataSourceDelegate.h"

@implementation UITableViewController (AccessDataSourceDelegate)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (self.tableView.dataSource == nil || ![self.tableView.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
		return 0;
	}
	return [self.tableView.dataSource numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.tableView.dataSource == nil || ![self.tableView.dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
		return 0;
	}
	return [self.tableView.dataSource tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.tableView.dataSource == nil || ![self.tableView.dataSource respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
		return nil;
	}
	return [self.tableView.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.tableView.delegate == nil || ![self.tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
		return;
	}
	return [self.tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
