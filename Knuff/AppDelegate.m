//
//  AppDelegate.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 14/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [Fabric with:@[[Crashlytics class]]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

@end
