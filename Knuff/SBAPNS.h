//
//  APNS.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBAPNS : NSObject
@property (nonatomic, strong, nullable) __attribute__((NSObject)) SecIdentityRef identity;
@property (nonatomic, copy, nullable) void(^APNSErrorBlock)(uint8_t status, NSString * __nonnull description, uint32_t identifier);

- (void)pushPayload:(nonnull NSDictionary *)payload
            toToken:(nonnull NSString *)token
          withTopic:(nullable NSString *)topic
           priority:(NSUInteger)priority
          inSandbox:(BOOL)sandbox;
@end
