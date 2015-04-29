//
//  APNSDevicesViewController.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class APNSDevicesViewController;
@class APNSServiceDevice;

@protocol APNSDevicesViewControllerDelegate <NSObject>

- (void)deviceViewController:(APNSDevicesViewController *)viewController didSelectDevice:(APNSServiceDevice *)device;

@end

@interface APNSDevicesViewController : NSViewController
@property (weak) id<APNSDevicesViewControllerDelegate> delegate;
@end
