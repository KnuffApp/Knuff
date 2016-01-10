//
//  APNSDocument.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 14/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "APNSItem.h"

@interface APNSDocument : NSDocument
@property NSString *token;
@property NSString *payload;
@property APNSItemMode mode;
@property NSString *certificateDescription; // Unused
@property APNSItemPriority priority;
@property BOOL sandbox;
@end

