//
//  APNSFrameBuilder.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 11/04/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSFrameBuilder.h"

@implementation APNSFrameBuilder

+ (NSData *)dataFromToken:(NSString *)token
                 playload:(NSDictionary *)payload
               identifier:(uint32_t)identifier
           expirationDate:(uint32_t)expirationDate
                 priority:(uint8_t)priority {
  
  // https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW1
  
  NSData *payloadData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

  NSMutableData *tokenData = [NSMutableData data];
  unsigned value;
  NSScanner *scanner = [NSScanner scannerWithString:token];
  while(![scanner isAtEnd]) {
    [scanner scanHexInt:&value];
    value = htonl(value);
    [tokenData appendBytes:&value length:sizeof(value)];
  }
  
  // frame
  NSMutableData *frame = [NSMutableData data];
  
  uint8_t itemId = 0;
  uint16_t itemLength = 0;
  
  // item 1, token
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // token length, network order
  itemLength = htons([tokenData length]);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // token
  [frame appendData:tokenData];
  
  // item 2, payload
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // payload length, network order
  itemLength = htons([payloadData length]);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // payload
  [frame appendData:payloadData];
  
  // item 3, notification identifier
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // notification identifier length, network order
  itemLength = htons(4);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // notification identifier, network order
  uint32_t notificationIdentifier = htonl(0);
  [frame appendBytes:&notificationIdentifier length:sizeof(uint32_t)];
  
  // item 4, expiration date
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // expiration date lenght, network order
  itemLength = htons(4);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // expiration date, network order
  expirationDate = htonl(expirationDate);
  [frame appendBytes:&expirationDate length:sizeof(uint32_t)];
  
  // item 5, priority
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // priority length, network order
  itemLength = htons(1);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // priority
  [frame appendBytes:&priority length:sizeof(uint8_t)];
  
  // data
  NSMutableData *data = [NSMutableData data];
  
  // command
  uint8_t command = 2;
  [data appendBytes:&command length:sizeof(uint8_t)];
  
  // frame length, network order
  uint32_t frameLength = htonl([frame length]);
  [data appendBytes:&frameLength length:sizeof(uint32_t)];
  
  // frame
  [data appendData:frame];

  return [data copy];
}

@end
