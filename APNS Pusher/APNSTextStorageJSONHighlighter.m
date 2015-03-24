//
//  APNSTextStorageJSONHighlighter.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 19/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSTextStorageJSONHighlighter.h"
#import "PEGKit.h"
#import "JSONParser.h"

@interface APNSTextStorageJSONHighlighter ()
@property (nonatomic, strong) NSTextStorage *storage;
@property (nonatomic, strong) JSONParser *parser;
@end

@implementation APNSTextStorageJSONHighlighter

- (instancetype)init {
  if (self = [super init]) {
    self.parser = [[JSONParser alloc] initWithDelegate:self];
    self.parser.enableAutomaticErrorRecovery = YES;
  }
  
  return self;
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification {
  NSTextStorage *storage = notification.object;
  self.storage = storage;
  
  NSData *data = [storage.string dataUsingEncoding:NSUTF8StringEncoding];
  
  if (data) {
    NSError *error;
    [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  
    if (error) {
      NSLog(@"%@", error);
    }
  }
  
  [storage removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, storage.string.length)];
  
  
  NSError *error;
  [self.parser parseString:storage.string error:&error];
}

- (void)parser:(JSONParser *)parser didMatchStart:(id)start {
  
}

- (void)parser:(JSONParser *)parser didMatchObject:(id)object {
  
}

- (void)parser:(JSONParser *)parser didMatchPropertyName:(PKAssembly *)propertyName {
  PKToken *token = propertyName.stack.lastObject;
  
  if (token) {
    [self.storage addAttribute:NSForegroundColorAttributeName
                         value:[NSColor redColor]
                         range:NSMakeRange(token.offset, token.stringValue.length)];
  }
}

@end
