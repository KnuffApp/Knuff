//
//  APNSServiceBrowser.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APNSServiceBrowser : NSObject
@property (nonatomic) BOOL searching;
@property (nonatomic, strong, readonly) NSMutableArray *devices; // KVO

+ (instancetype)browser;
@end
