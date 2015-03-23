//
//  APNSTextStorageJSONHighlighter.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 19/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSTextStorageJSONHighlighter.h"

@interface APNSTextStorageJSONHighlighter ()
@end

@implementation APNSTextStorageJSONHighlighter

- (instancetype)init {
  if (self = [super init]) {
  }
  
  return self;
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification {
  NSTextStorage *storage = notification.object;
}

@end
