//
//  APNSSecIdentityType.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 15/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSSecIdentityType.h"

// http://www.apple.com/certificateauthority/Apple_WWDR_CPS
static NSString * const APNSSecIdentityTypeDevelopmentCustomExtension = @"1.2.840.113635.100.6.3.1";
static NSString * const APNSSecIdentityTypeProductionCustomExtension = @"1.2.840.113635.100.6.3.2";
static NSString * const APNSSecIdentityTypeUniversalCustomExtension = @"1.2.840.113635.100.6.3.6";

APNSSecIdentityType APNSSecIdentityGetType(SecIdentityRef identity, NSArray ** topics) {
  
  SecCertificateRef certificate;
  SecIdentityCopyCertificate(identity, &certificate);
  NSArray *keys = @[
                    APNSSecIdentityTypeDevelopmentCustomExtension,
                    APNSSecIdentityTypeProductionCustomExtension,
                    APNSSecIdentityTypeUniversalCustomExtension,
                    ];
  NSDictionary *values = (__bridge_transfer NSDictionary *)SecCertificateCopyValues(certificate, (__bridge CFArrayRef)keys, NULL);
  
  CFRelease(certificate);
  
  if (values[APNSSecIdentityTypeDevelopmentCustomExtension] && values[APNSSecIdentityTypeProductionCustomExtension]) {
    
    // Extract topics
    if (topics != NULL) {
      NSDictionary *topicContents = values[APNSSecIdentityTypeUniversalCustomExtension];
      if (topicContents) {
        NSMutableArray *array = [NSMutableArray new];
        NSArray *topicArray = topicContents[@"value"];
        
        for (NSDictionary *topic in topicArray) {
          if ([topic[@"label"] isEqualToString:@"Data"]) {
            [array addObject:topic[@"value"]];
          }
        }
        *topics = array;
      }
    }
    
    return APNSSecIdentityTypeUniversal;
  } else if (values[APNSSecIdentityTypeDevelopmentCustomExtension]) {
    return APNSSecIdentityTypeDevelopment;
  } else if (values[APNSSecIdentityTypeProductionCustomExtension]) {
    return APNSSecIdentityTypeProduction;
  } else {
    return APNSSecIdentityTypeInvalid;
  }
}
