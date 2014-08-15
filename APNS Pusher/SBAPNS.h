//
//  APNS.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBAPNS : NSObject
@property (nonatomic, assign) SecIdentityRef identity;
@property (nonatomic, copy) void(^errorBlock)(uint8_t status, NSString *description, uint32_t identifier);

- (void)pushPayload:(NSDictionary *)payload withToken:(NSString *)token;
@end
