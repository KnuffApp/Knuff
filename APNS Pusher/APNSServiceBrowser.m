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
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:@"apns-pusher"];
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

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
  APNSServiceDevice *device = [APNSServiceDevice new];
  device.displayName = peerID.displayName;
  device.token = info[@"token"];
  device.type = [info[@"type"] isEqualTo:@"iOS"]?APNSServiceDeviceTypeIOS:APNSServiceDeviceTypeOSX;
  
  [self.devices addObject:device];
  [self.peerIDToDeviceMap setObject:device forKey:peerID];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
  APNSServiceDevice *device = [self.peerIDToDeviceMap objectForKey:peerID];
  
  [self.devices removeObject:device];
  [self.peerIDToDeviceMap removeObjectForKey:peerID];
}

@end
