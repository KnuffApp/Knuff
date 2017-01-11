//
//  APNSSecIdentityType.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

typedef NS_ENUM(NSInteger, APNSSecIdentityType) {
  APNSSecIdentityTypeInvalid,
  APNSSecIdentityTypeDevelopment,
  APNSSecIdentityTypeProduction,
  APNSSecIdentityTypeUniversal
};

NSArray<NSString *> * APNSSecIdentityGetTopics(SecIdentityRef identity);
extern APNSSecIdentityType APNSSecIdentityGetType(SecIdentityRef identity);
