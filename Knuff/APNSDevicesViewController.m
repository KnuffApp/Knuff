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
#import "FBKVOController.h"

@interface APNSDevicesViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) FBKVOController *KVOController;
@end

@implementation APNSDevicesViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    self.KVOController = [FBKVOController controllerWithObserver:self];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.KVOController observe:[APNSServiceBrowser browser] keyPath:@"devices" options:NSKeyValueObservingOptionNew block:^(APNSDevicesViewController *observer, APNSServiceBrowser* object, NSDictionary *change) {
    if ([change[NSKeyValueChangeKindKey] isEqual: @(NSKeyValueChangeInsertion)]) {
      [observer.tableView insertRowsAtIndexes:change[NSKeyValueChangeIndexesKey] withAnimation:NSTableViewAnimationEffectFade];
    } else if ([change[NSKeyValueChangeKindKey] isEqual: @(NSKeyValueChangeRemoval)]) {
      [observer.tableView removeRowsAtIndexes:change[NSKeyValueChangeIndexesKey] withAnimation:NSTableViewAnimationEffectFade];
    }
  }];
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
  
  return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  if (self.tableView.selectedRow != -1) {
    APNSServiceDevice *device = [APNSServiceBrowser browser].devices[self.tableView.selectedRow];
    
    [self.delegate deviceViewController:self didSelectDevice:device];
  }
}

@end
