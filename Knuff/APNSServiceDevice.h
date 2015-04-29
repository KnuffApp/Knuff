//
//  APNSServiceDevice.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APNSServiceDevice : NSObject
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *token;
@end
