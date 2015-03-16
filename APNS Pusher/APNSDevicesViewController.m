//
//  APNSDevicesViewController.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSDevicesViewController.h"
#import "APNSServiceBrowser.h"
#import "APNSServiceDevice.h"
#import "APNSDeviceTableCellView.h"

@interface APNSDevicesViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@end

@implementation APNSDevicesViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

#pragma mark -

- (IBAction)copyToken:(id)sender {
  if (self.tableView.clickedRow != -1) {
    APNSServiceDevice *device = [APNSServiceBrowser browser].devices[self.tableView.clickedRow];
    
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    [pasteBoard setString:device.token forType:NSPasteboardTypeString];
  }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [APNSServiceBrowser browser].devices.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  APNSDeviceTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
  
  APNSServiceDevice *device = [APNSServiceBrowser browser].devices[row];
  
  cellView.textField.stringValue = device.displayName;
  cellView.tokenTextField.stringValue = device.token;
  
  if (device.type == APNSServiceDeviceTypeIOS) {
    cellView.imageView.image = [NSImage imageNamed:@"iphone"];
  } else {
    cellView.imageView.image = [NSImage imageNamed:@"imac"];
  }
  
  return cellView;
}

@end
