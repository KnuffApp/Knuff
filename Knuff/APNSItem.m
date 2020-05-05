//
//  APNSItem.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 14/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSItem.h"

@implementation APNSItem
@end

APNSItemPushType APNSItemPushTypeDefault(void) {
  return APNSItemPushTypeAlert;
}

NSString *APNSItemPushTypeToStr(APNSItemPushType pushType) {
  switch (pushType) {
    case APNSItemPushTypeAlert:
      return @"alert"; //0
    case APNSItemPushTypeBackground:
      return @"background"; //1
    case APNSItemPushTypeVoip:
      return @"voip"; //2
    case APNSItemPushTypeComplication:
      return @"complication"; //3
    case APNSItemPushTypeFileProvider:
      return @"fileprovider"; //4
    case APNSItemPushTypeMDM:
      return @"mdm"; //5
  }
}

APNSItemPushType APNSItemPushTypeFromStr(NSString *pushTypeStr) {
  if ([pushTypeStr isEqualToString:APNSItemPushTypeToStr(APNSItemPushTypeAlert)]) {
    return APNSItemPushTypeAlert;
  }
  else if ([pushTypeStr isEqualToString:APNSItemPushTypeToStr(APNSItemPushTypeBackground)]) {
    return APNSItemPushTypeBackground;
  }
  else if ([pushTypeStr isEqualToString:APNSItemPushTypeToStr(APNSItemPushTypeVoip)]) {
    return APNSItemPushTypeVoip;
  }
  else if ([pushTypeStr isEqualToString:APNSItemPushTypeToStr(APNSItemPushTypeComplication)]) {
    return APNSItemPushTypeComplication;
  }
  else if ([pushTypeStr isEqualToString:APNSItemPushTypeToStr(APNSItemPushTypeFileProvider)]) {
    return APNSItemPushTypeFileProvider;
  }
  else if ([pushTypeStr isEqualToString:APNSItemPushTypeToStr(APNSItemPushTypeMDM)]) {
    return APNSItemPushTypeMDM;
  }
  else {
    return APNSItemPushTypeDefault();
  }
}

NSArray<NSString *> *APNSItemPushTypesAll(void) {
  return @[
    APNSItemPushTypeToStr(APNSItemPushTypeAlert),
    APNSItemPushTypeToStr(APNSItemPushTypeBackground),
    APNSItemPushTypeToStr(APNSItemPushTypeVoip),
    APNSItemPushTypeToStr(APNSItemPushTypeComplication),
    APNSItemPushTypeToStr(APNSItemPushTypeFileProvider),
    APNSItemPushTypeToStr(APNSItemPushTypeMDM),
  ];
}
