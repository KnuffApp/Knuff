//
//  APNSidentityExporter.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 28/04/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APNSidentityExporter : NSObject

+ (void)exportIdentity:(SecIdentityRef)identity withPanelWindow:(NSWindow *)window;

@end
