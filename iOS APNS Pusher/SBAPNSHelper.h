//
//  SBAPNSHelper.h
//  APNS Pusher
//
//  Created by Prince on 13/6/30.
//  Copyright (c) 2013年 Doubleint. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBAPNSHelper : NSObject

@property (nonatomic, readonly)NSString *identityName;

+ (SBAPNSHelper *)sharedAPNSHelper;
- (void)pushPayload:(NSDictionary *)payload withToken:(NSString *)token andSandbox:(BOOL)sandbox;

@end
