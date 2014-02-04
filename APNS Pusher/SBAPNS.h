//
//  APNS.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@interface SBAPNS : NSObject
@property (nonatomic, assign, readonly, getter = isReady) BOOL ready;
@property (nonatomic, assign) SecIdentityRef identity;
@property (nonatomic, assign, getter = isSandbox) BOOL sandbox;
@property (nonatomic, copy) void(^errorBlock)(uint8_t status, NSString *description, uint32_t identifier);

- (void)pushPayload:(NSDictionary *)payload withToken:(NSString *)token;
@end
