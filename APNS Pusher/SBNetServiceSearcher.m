//
//  SBNetServiceSearcher.m
//  APNS Pusher
//
//  Created by Simon Blommegård on 2012-10-31.
//  Copyright (c) 2012 Simon Blommegård. All rights reserved.
//

#import "SBNetServiceSearcher.h"

@interface SBNetServiceSearcher () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (nonatomic, strong) NSMutableArray *availableNetServices;
@property (nonatomic, strong) NSNetServiceBrowser *netServiceBrowser;
@end

@implementation SBNetServiceSearcher

#pragma mark - Properties

- (void)setSearching:(BOOL)searching {
	if(_searching && !searching) {
		[_netServiceBrowser stop];
		
    [self setNetServiceBrowser:nil];
    [self.availableNetServices removeAllObjects];
	} else if(!_searching && searching) {
    [self setAvailableNetServices:[NSMutableArray new]];
		[self setNetServiceBrowser:[NSNetServiceBrowser new]];
    
		[_netServiceBrowser setDelegate:self];
		[_netServiceBrowser searchForServicesOfType:@"_apnspusher._tcp" inDomain:@""];
	}
	
	_searching = (_netServiceBrowser != nil);
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	[self.availableNetServices addObject:netService];
	[netService setDelegate:self];
	[netService resolveWithTimeout:10.];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	[self.availableNetServices removeObject:aNetService];
  
  // Kick KVO for bindings
  [self willChangeValueForKey:@"availableNetServices"];
  [self didChangeValueForKey:@"availableNetServices"];
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
  // Kick KVO for bindings
  [self willChangeValueForKey:@"availableNetServices"];
  [self didChangeValueForKey:@"availableNetServices"];
}

@end
