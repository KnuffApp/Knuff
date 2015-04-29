//
//  APNSFrameBuilder.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 11/04/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APNSFrameBuilder : NSData

+ (NSData *)dataFromToken:(NSString *)token
                 playload:(NSDictionary *)payload
               identifier:(uint32_t)identifier
           expirationDate:(uint32_t)expirationDate
                 priority:(uint8_t)priority;

@end
