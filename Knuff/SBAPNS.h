//
//  APNS.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SBAPNS;

NS_ASSUME_NONNULL_BEGIN

@protocol SBAPNSDelegate <NSObject>
- (void)APNS:(SBAPNS *)APNS didRecieveStatus:(NSInteger)statusCode reason:(NSString *)reason forID:(nullable NSString *)ID;
- (void)APNS:(SBAPNS *)APNS didFailWithError:(NSError *)error;
@end

@interface SBAPNS : NSObject
@property (nonatomic, strong, nullable) __attribute__((NSObject)) SecIdentityRef identity;
@property (nonatomic, weak, nullable) id<SBAPNSDelegate> delegate;

- (void)pushPayload:(NSDictionary *)payload
            toToken:(NSString *)token
          withTopic:(nullable NSString *)topic
           priority:(NSUInteger)priority
         collapseID:(nullable NSString *)collapseID
        payloadType:(NSUInteger)payloadType
          inSandbox:(BOOL)sandbox;
@end

NS_ASSUME_NONNULL_END
