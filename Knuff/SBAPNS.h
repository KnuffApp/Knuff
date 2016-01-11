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
@property (nonatomic, copy, nullable) void(^connectionErrorBlock)();

- (void)pushPayload:(nonnull NSDictionary *)payload toToken:(nonnull NSString *)token withPriority:(NSUInteger)priority;
@end
