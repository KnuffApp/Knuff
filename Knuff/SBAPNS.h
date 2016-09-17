//
//  APNS.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "APNSIdentity.h"

@class SBAPNS;

@protocol SBAPNSDelegate <NSObject>

- (void)APNS:(nonnull SBAPNS *)APNS didRecieveStatus:(NSInteger)statusCode reason:(nonnull NSString *)reason forID:(nullable NSString *)ID;
- (nonnull APNSIdentity *)identityForAPNS:(nonnull SBAPNS *)APNS;

@end

@interface SBAPNS : NSObject
@property (nonatomic, weak, nullable) id<SBAPNSDelegate> delegate;

- (void)pushPayload:(nonnull NSDictionary *)payload
            toToken:(nonnull NSString *)token
          withTopic:(nullable NSString *)topic
           priority:(NSUInteger)priority
          inSandbox:(BOOL)sandbox;
@end
