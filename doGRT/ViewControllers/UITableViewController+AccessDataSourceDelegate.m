//
//  UITableViewController+AccessDataSourceDelegate.m
//  doGRT
//
//  Created by Greg Wang on 12-10-2.
//
//

#import "UITableViewController+AccessDataSourceDelegate.h"

@implementation UITableViewController (AccessDataSourceDelegate)

#pragma mark - data source

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (self.tableView.dataSource == nil || ![self.tableView.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
		return 0;
	}
	return [self.tableView.dataSource numberOfSectionsInTableView:tableView];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.tableView.dataSource == nil || ![self.tableView.dataSource respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)]) {
		return YES;
	}
	return [self.tableView.dataSource tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.tableView.dataSource == nil || ![self.tableView.dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)]) {
		return NO;
	}
	return [self.tableView.dataSource tableView:tableView canMoveRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.tableView.dataSource == nil || ![self.tableView.dataSource respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
		return;
	}
	return [self.tableView.dataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	if (self.tableView.dataSource == nil || ![self.tableView.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]) {
		return;
	}
	return [self.tableView.dataSource tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
}

#pragma mark - delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (self.tableView.delegate == nil || ![self.tableView.delegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)]) {
		return;
	}
	return [self.tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.tableView.delegate == nil || ![self.tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
		return;
	}
	return [self.tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.tableView.delegate == nil || ![self.tableView.delegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)]) {
		return UITableViewCellEditingStyleDelete;
	}
	return [self.tableView.delegate tableView:tableView editingStyleForRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if (self.tableView.delegate == nil || ![self.tableView.delegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) {
		return proposedDestinationIndexPath;
	}
	return [self.tableView.delegate tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:proposedDestinationIndexPath];
}
@end
