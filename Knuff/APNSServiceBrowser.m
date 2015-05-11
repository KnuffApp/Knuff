//
//  APNSServiceBrowser.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSServiceBrowser.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "APNSServiceDevice.h"

@interface APNSServiceBrowser () <MCNearbyServiceBrowserDelegate>
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) NSMapTable *peerIDToDeviceMap;

@property (nonatomic, strong) NSMutableArray *devices;
@end

@implementation APNSServiceBrowser

- (instancetype)init {
  if (self = [super init]) {
    self.peerIDToDeviceMap = [NSMapTable strongToStrongObjectsMapTable];
    self.devices = [NSMutableArray new];
    
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:[[NSHost currentHost] localizedName]];
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:@"knuff"];
    self.browser.delegate = self;
  }
  return self;
}

#pragma mark -

- (void)setSearching:(BOOL)searching {
  if (_searching != searching){
    _searching = searching;
    
    if (searching) {
      [self.browser startBrowsingForPeers];
    } else {
      [self.browser stopBrowsingForPeers];
    }
  }
}

#pragma mark -

+ (instancetype)browser {
  static dispatch_once_t onceToken;
  static APNSServiceBrowser *browser;
  
  dispatch_once(&onceToken, ^{
    browser = [APNSServiceBrowser new];
  });
  
  return browser;
}

#pragma mark -

- (void)insertObject:(APNSServiceDevice *)device inDevicesAtIndex:(NSUInteger)index {
  [self.devices insertObject:device atIndex:index];
}

- (void)removeObjectFromDevicesAtIndex:(NSUInteger)index {
  [self.devices removeObjectAtIndex:index];
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
  APNSServiceDevice *device = [APNSServiceDevice new];
  device.displayName = peerID.displayName;
  device.token = info[@"token"];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self insertObject:device inDevicesAtIndex:self.devices.count];
    [self.peerIDToDeviceMap setObject:device forKey:peerID];
  });
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
  APNSServiceDevice *device = [self.peerIDToDeviceMap objectForKey:peerID];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self removeObjectFromDevicesAtIndex:[self.devices indexOfObject:device]];
    [self.peerIDToDeviceMap removeObjectForKey:peerID];
  });
}

@end
