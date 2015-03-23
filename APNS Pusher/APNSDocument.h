//
//  APNSDocument.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 14/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APNSDocument : NSDocument
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *payload;
@end

