//
//  UITableViewController+AccessDataSourceDelegate.h
//  doGRT
//
//  Created by Greg Wang on 12-10-2.
//
//

@interface UITableViewController (AccessDataSourceDelegate)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end
