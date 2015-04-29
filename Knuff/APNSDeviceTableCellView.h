//
//  APNSDeviceTableCellView.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APNSDeviceTableCellView : NSTableCellView
@property (weak) IBOutlet NSTextField *tokenTextField;
@end
