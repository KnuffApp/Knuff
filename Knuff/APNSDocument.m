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
#import <Fragaria/Fragaria.h>

@interface APNSDocument ()
@property (nonatomic, strong) APNSItem *item;
@end

@implementation APNSDocument

@dynamic token, payload;

- (instancetype)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
  if (self = [super initWithType:typeName error:outError]) {
    self.item = [APNSItem new];
    self.item.payload = @"{\n\t\"aps\":{\n\t\t\"alert\":\"Test\",\n\t\t\"sound\":\"default\",\n\t\t\"badge\":1\n\t}\n}";
    self.item.priority = APNSItemPriorityImmediately;
  }
  return self;
}

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
  
  APNSViewController *viewController = (APNSViewController *)windowController.contentViewController;
  viewController.representedObject = self;
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

- (void)setToken:(NSString *)token {
  [[self.undoManager prepareWithInvocationTarget:self] setToken:self.token];
  
  self.item.token = token;
}

- (NSString *)token {
  return self.item.token;
}

- (void)setPayload:(NSString *)payload {
  self.item.payload = payload;
}

- (NSString *)payload {
  return self.item.payload;
}

- (void)setMode:(APNSItemMode)mode {
  [(APNSDocument *)[self.undoManager prepareWithInvocationTarget:self] setMode:self.mode];
  
  self.item.mode = mode;
}

- (APNSItemMode)mode {
  return self.item.mode;
}

- (void)setCertificateDescription:(NSString *)certificateDescription {
  [[self.undoManager prepareWithInvocationTarget:self] setCertificateDescription:self.certificateDescription];
  
  self.item.certificateDescription = certificateDescription;
}

- (NSString *)certificateDescription {
  return self.item.certificateDescription;
}

- (void)setPriority:(APNSItemPriority)priority {
  [(APNSDocument *)[self.undoManager prepareWithInvocationTarget:self] setPriority:self.priority];
  
  self.item.priority = priority;
}

- (APNSItemPriority)priority {
  return self.item.priority;
}

- (void)setSandbox:(BOOL)sandbox {
  [(APNSDocument *)[self.undoManager prepareWithInvocationTarget:self] setSandbox:self.sandbox];
  
  self.item.sandbox = sandbox;
}

- (BOOL)sandbox {
  return self.item.sandbox;
}

- (void)dealloc {}
@end
