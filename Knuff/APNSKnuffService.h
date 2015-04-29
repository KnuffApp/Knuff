//
//  APNSKnuffService.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 24/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APNSKnuffService : NSObject
- (void)pushPayload:(NSDictionary *)payload
            toToken:(NSString *)token
       withPriority:(NSUInteger)priority
             expiry:(NSUInteger)expiry;
@end
