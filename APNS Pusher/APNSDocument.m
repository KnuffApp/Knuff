//
//  APNSDocument.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 14/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSDocument.h"
#import "APNSViewController.h"
#import "APNSItem.h"

@interface APNSDocument ()
@property (nonatomic, strong) APNSItem *item;

@property (weak) APNSViewController *viewController;
@end

@implementation APNSDocument

- (instancetype)init {
    self = [super init];
    if (self) {
    // Add your subclass-specific initialization here.
    }
    return self;
}

+ (BOOL)autosavesInPlace {
  return YES;
}

- (void)makeWindowControllers {
  // Override to return the Storyboard file name of the document.
  NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
  NSWindowController *windowController = [storyboard instantiateControllerWithIdentifier:@"Document Window Controller"];
  [self addWindowController:windowController];
  
  self.viewController = (APNSViewController *)windowController.contentViewController;
  self.viewController.windowController = windowController;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.item];
  
  if (!data) {
    *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
    return nil;
  }
  
  return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
  self.item = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  
  if (!self.item) {
    *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
    return NO;
  }
  
  return YES;
}

@end
