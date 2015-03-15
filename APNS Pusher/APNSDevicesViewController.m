//
//  APNSDevicesViewController.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSDevicesViewController.h"

@interface APNSDevicesViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@end

@implementation APNSDevicesViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return 2;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
  cellView.textField.stringValue = @"asd";
  
  if (row == 0) {
    cellView.imageView.image = [NSImage imageNamed:@"iphone"];
  } else {
    cellView.imageView.image = [NSImage imageNamed:@"imac"];
  }
  return cellView;
}

@end
