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

APNSSecIdentityType APNSSecIdentityGetType(SecIdentityRef identity) {
  
  SecCertificateRef certificate;
  SecIdentityCopyCertificate(identity, &certificate);
  NSArray *keys = @[
                    APNSSecIdentityTypeDevelopmentCustomExtension,
                    APNSSecIdentityTypeProductionCustomExtension
                    ];
  NSDictionary *values = (__bridge_transfer NSDictionary *)SecCertificateCopyValues(certificate, (__bridge CFArrayRef)keys, NULL);
  CFRelease(certificate);
  
  if (values[APNSSecIdentityTypeDevelopmentCustomExtension]) {
    return APNSSecIdentityTypeDevelopment;
  } else if (values[APNSSecIdentityTypeProductionCustomExtension]) {
    return APNSSecIdentityTypeProduction;
  } else {
    return APNSSecIdentityTypeInvalid;
  }
}
