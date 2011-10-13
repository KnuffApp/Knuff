//
//  APNS.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APNS : NSObject
@property (nonatomic, assign) SecIdentityRef identity;
@property (nonatomic, assign, getter = isSandbox) BOOL sandbox;
@property (nonatomic, copy) void(^errorBlock)(uint8_t status, NSString *description, uint32_t identifier);
+ (APNS *)sharedAPNS;

- (void)pushWithToken:(NSString *)token alert:(NSString *)alert sound:(NSString *)sound badge:(NSInteger)badge;
@end
