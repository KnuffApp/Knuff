//
//  APNSViewController.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 14/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSViewController.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <Security/Security.h>
#import "APNSSecIdentityType.h"

#import "SBAPNS.h"
#import "APNSKnuffService.h"

#import "APNSServiceBrowser.h"
#import "APNSDevicesViewController.h"
#import "APNSServiceDevice.h"

#import "APNSDocument.h"
#import "APNSItem.h"

#import "APNSidentityExporter.h"

#import "FBKVOController.h"

#import <MGSFragaria/MGSFragaria.h>
#import "pop.h"

@interface APNSViewController () <NSTextDelegate, APNSDevicesViewControllerDelegate, NSPopoverDelegate, NSTextViewDelegate>
@property (nonatomic, strong) FBKVOController *KVOController;

@property (nonatomic, strong) SBAPNS *APNS;
@property (nonatomic, strong) APNSKnuffService *knuffService;

@property (nonatomic, assign, readonly) NSString *identityName;

@property (weak) IBOutlet NSView *identityView;

@property (weak) IBOutlet NSView *payloadView;

@property (nonatomic) BOOL showDevices; // current state of the UI

@property (weak) IBOutlet NSTextField *tokenTextField;
@property (weak) IBOutlet NSButton *devicesButton;

@property (nonatomic, strong, readonly) NSDictionary *payload;

@property (weak) IBOutlet NSView *customView;
@property (nonatomic, strong) MGSFragaria *fragaria;

@property (nonatomic, strong) NSPopover *devicesPopover;

@property (nonatomic) APNSItemMode mode; // current state of the UI
@property (weak) IBOutlet NSSegmentedControl *modeSegmentedControl;

@property (weak) IBOutlet NSSegmentedControl *prioritySegmentedControl; // Only 5 and 10
@end

@implementation APNSViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    self.KVOController = [FBKVOController controllerWithObserver:self];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self APNS];
  
  [APNSServiceBrowser browser].searching = YES;
  
  // It is layouted like this in the storyboard
  self.showDevices = YES;
  
  [self.KVOController observe:[APNSServiceBrowser browser]
                      keyPath:@"devices"
                      options:NSKeyValueObservingOptionNew
                        block:^(APNSViewController *observer, APNSServiceBrowser* object, NSDictionary *change) {
                          [observer devicesDidChange:NO];
                        }];
  
  [self devicesDidChange:YES];
}

- (void)viewDidDisappear {
  [super viewDidDisappear];
  
  
  self.APNS = nil;
  
  // This shit is leaking worse than I thought, but I am not in the mood of writing my own editor.
  NSArray *array = [[self.customView subviews] copy];
  
  for (NSView *view in array) {
    [view removeFromSuperview];
  }
  
  self.fragaria = nil;
}

#pragma mark -

- (IBAction)exportIdentity:(id)sender {
  [APNSIdentityExporter exportIdentity:self.APNS.identity withPanelWindow:self.document.windowForSheet];
}

- (IBAction)changeMode:(NSSegmentedControl *)sender {
  APNSItemMode mode = sender.selectedSegment;

  if (mode != self.document.mode) {
    self.document.mode = mode;
  }
}

- (IBAction)presentDevices:(id)sender {
  NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
  APNSDevicesViewController *viewController = [storyboard instantiateControllerWithIdentifier:@"Devices View Controller"];
  viewController.delegate = self;
  
  NSPopover *popover = [[NSPopover alloc] init];
  popover.contentViewController = viewController;
  
  popover.delegate = self;
  popover.animates = YES;
  popover.behavior = NSPopoverBehaviorTransient;
  [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
  
  self.devicesPopover = popover;
}

- (IBAction)chooseIdentity:(id)sender {
  SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
  [panel setAlternateButtonTitle:@"Cancel"];
  
  [panel beginSheetForWindow:self.document.windowForSheet
               modalDelegate:self
              didEndSelector:@selector(chooseIdentityPanelDidEnd:returnCode:contextInfo:)
                 contextInfo:nil
                  identities:[self identities]
                     message:@"Choose the identity to use for delivering notifications: \n(Issued by Apple in the Provisioning Portal)"];
}

- (IBAction)changePriority:(NSSegmentedControl *)sender {
  APNSItemPriority priority = (sender.selectedSegment == 0) ? APNSItemPriorityLater:APNSItemPriorityImmediately;
  
  if (priority != self.document.priority) {
    self.document.priority = priority;
  }
}

-(void)chooseIdentityPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSFileHandlingPanelOKButton) {
    SecIdentityRef identity = [SFChooseIdentityPanel sharedChooseIdentityPanel].identity;
    [self willChangeValueForKey:@"identityName"];
    [self.APNS setIdentity:identity];
    [self didChangeValueForKey:@"identityName"];
  }
}

- (IBAction)push:(id)sender {
  // TODO: Check payload
  
//  uint8_t priority = 10;
//  
//  NSArray *APSKeys = [[self.payload objectForKey:@"aps"] allKeys];
//  if (APSKeys.count == 1 && [APSKeys.lastObject isEqualTo:@"content-available"]) {
//    priority = 5;
//  }
  
  
  if (self.APNS.identity != NULL) {
    [self.APNS pushPayload:self.payload
                   toToken:[self preparedToken]
              withPriority:self.document.priority];
  } else {
    [self.knuffService pushPayload:self.payload
                           toToken:[self preparedToken]
                      withPriority:self.document.priority
                            expiry:0];
    
//    NSAlert *alert = [NSAlert new];
//    [alert addButtonWithTitle:@"OK"];
//    alert.messageText = @"Missing identity";
//    alert.informativeText = @"You have not choosen an identity for signing the notification.";
//    
//    [alert beginSheetModalForWindow:self.windowController.window completionHandler:nil];
  }
  

}

- (void)modeDidChange:(BOOL)initial {
  // Update UI
  [self setMode:self.document.mode animated:!initial];
  
  // disconnect from APNS socket
  if (self.document.mode == APNSItemModeKnuff) {
    [self willChangeValueForKey:@"identityName"];
    self.APNS.identity = NULL;
    [self didChangeValueForKey:@"identityName"];
  }
}

- (void)devicesDidChange:(BOOL)initial {
  APNSServiceBrowser *browser = [APNSServiceBrowser browser];

  NSLog(@"%@", @(browser.devices.count));
  
  BOOL changed = NO;
  
  CGFloat devicesButtonAlpha = self.devicesButton.alphaValue;
  NSRect textFieldRect = self.tokenTextField.frame;
  
  // Hide
  if (self.showDevices && browser.devices.count == 0) {
    devicesButtonAlpha = 0;
    textFieldRect.size.width = self.payloadView.bounds.size.width - textFieldRect.origin.x;
    
    changed = YES;
  }
  // Show
  else if (!self.showDevices && browser.devices.count > 0) {
    devicesButtonAlpha = 1;
    textFieldRect.size.width = self.payloadView.bounds.size.width - textFieldRect.origin.x - self.devicesButton.bounds.size.width - 8;

    changed = YES;
  }
  
  if (changed) {
    self.showDevices = !self.showDevices;
    
    if (initial) {
      self.devicesButton.alphaValue = devicesButtonAlpha;
      self.tokenTextField.frame = textFieldRect;
      self.devicesButton.hidden = !self.showDevices;
    } else {
      if (self.showDevices) {
        self.devicesButton.hidden = NO;
      }
      
      POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlphaValue];
      animation.toValue = @(devicesButtonAlpha);
      animation.completionBlock = ^(POPAnimation *ani, BOOL finished) {
        if (!self.showDevices) {
          self.devicesButton.hidden = YES;
        }
      };
      
      [self.devicesButton pop_addAnimation:animation forKey:nil];
      
      animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
      animation.toValue = [NSValue valueWithRect:textFieldRect];
      
      [self.tokenTextField pop_addAnimation:animation forKey:nil];
    }
  }
}

- (void)priorityDidChange {
  APNSItemPriority priority = self.document.priority;
  
  [self.prioritySegmentedControl setSelectedSegment:(priority == APNSItemPriorityLater)?0:1];
}

#pragma mark -

- (void)setMode:(APNSItemMode)mode {
  [self setMode:mode animated:NO];
}

- (void)setMode:(APNSItemMode)mode animated:(BOOL)animated {
  if (self.mode != mode) {
    _mode = mode;
    
    BOOL knuff = (mode == APNSItemModeKnuff);
    
    // Correct segment
    self.modeSegmentedControl.selectedSegment = mode;
    
    // Diff
    CGFloat diff = 8 + self.identityView.bounds.size.height;
    
    // Hide / Show identity
    
    CGFloat identityViewAlphaVelue = knuff ? 0:1;
    
    NSRect windowFrame = self.view.window.frame;
    windowFrame.size.height = knuff ?
      (windowFrame.size.height - diff):
      (windowFrame.size.height + diff);
    
    windowFrame.origin.y = knuff ?
      (windowFrame.origin.y + diff):
      (windowFrame.origin.y - diff);
    
    if (!animated) {
      self.identityView.alphaValue = identityViewAlphaVelue;
      
      NSAutoresizingMaskOptions options = self.payloadView.autoresizingMask;
      self.payloadView.autoresizingMask = NSViewNotSizable;
      
      [self.view.window setFrame:windowFrame display:NO];
      
      self.payloadView.autoresizingMask = options;
    } else {
      if (!knuff) {
        self.identityView.hidden = NO;
      }
      
      POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlphaValue];
      
      [animation setCompletionBlock:^(POPAnimation *ani, BOOL fin) {
        if (knuff) {
          self.identityView.hidden = YES;
        }
      }];
      
      animation.toValue = @(identityViewAlphaVelue);
      [self.identityView pop_addAnimation:animation forKey:nil];
      
      //    // Move payload stuff up / down
      //    animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
      //
      //    NSRect rect = self.payloadView.frame;
      //    rect.origin.y = knuff ?
      //      (rect.origin.y + diff):
      //      (rect.origin.y - diff);
      //
      //    animation.toValue = [NSValue valueWithRect:rect];
      //    [self.payloadView pop_addAnimation:animation forKey:nil];
      
      // Ajust window
      
      // Make sure to move the payload with it
      NSAutoresizingMaskOptions options = self.payloadView.autoresizingMask;
      self.payloadView.autoresizingMask = NSViewNotSizable;
      
      animation = [POPSpringAnimation animationWithPropertyNamed:kPOPWindowFrame];
      

      
      [animation setCompletionBlock:^(POPAnimation *ani, BOOL fin) {
        self.payloadView.autoresizingMask = options;
      }];
      
      animation.toValue = [NSValue valueWithRect:windowFrame];
      [self.view.window pop_addAnimation:animation forKey:nil];
    }
  }
}

#pragma mark -

- (SBAPNS *)APNS {
  if (!_APNS) {
    _APNS = [SBAPNS new];
    __weak APNSViewController *weakSelf = self;
    [_APNS setAPNSErrorBlock:^(uint8_t status, NSString *description, uint32_t identifier) {
      
      NSAlert *alert = [NSAlert new];
      [alert addButtonWithTitle:@"OK"];
      alert.messageText = @"Error delivering notification";
      alert.informativeText = [NSString stringWithFormat:@"There was an error delivering the notificaton %d: %@", identifier, description];
      
      [alert beginSheetModalForWindow:weakSelf.document.windowForSheet completionHandler:nil];
    }];
  }
  return _APNS;
}

- (APNSKnuffService *)knuffService {
  if (!_knuffService) {
    _knuffService = [APNSKnuffService new];
  }
  return _knuffService;
}

- (MGSFragaria *)fragaria {
  if (!_fragaria) {
    _fragaria = [MGSFragaria new];
    
    [_fragaria setObject:self forKey:MGSFODelegate];
    [_fragaria setObject:@"JavaScript" forKey:MGSFOSyntaxDefinitionName];
  }
  return _fragaria;
}

#pragma mark -

- (void)setRepresentedObject:(APNSDocument *)representedObject {
  [self.KVOController unobserve:self.representedObject];

  super.representedObject = representedObject;
  
  [self.KVOController observe:representedObject
                      keyPath:@"token"
                      options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                        block:^(APNSViewController *observer, APNSDocument *object, NSDictionary *change) {
                          
                          if (object.token) {
                            [observer.tokenTextField setStringValue:object.token];
                          } else {
                            [observer.tokenTextField setStringValue:@""];
                          }
                        }];
  
  [self.KVOController observe:representedObject
                      keyPath:@"mode"
                      options:NSKeyValueObservingOptionNew
                        block:^(APNSViewController *observer, APNSDocument *object, NSDictionary *change) {
                          [observer modeDidChange:NO];
                        }];
  
  [self modeDidChange:YES];
  
  [self.KVOController observe:representedObject
                      keyPath:@"priority"
                      options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                        block:^(APNSViewController *observer, APNSDocument *object, NSDictionary *change) {
                          [observer priorityDidChange];
                        }];
  
  
  // This should be done in -viewDidLoad, but we have no document there, and no undo manager
  [self.fragaria embedInView:self.customView];
  [self.fragaria setString:representedObject.payload];
}

#pragma mark -

- (NSDictionary *)payload {
  NSData *data = [self.fragaria.string dataUsingEncoding:NSUTF8StringEncoding];
  
  if (data) {
    NSError *error;
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    
    if (payload && [payload isKindOfClass:[NSDictionary class]])
      return payload;
  }
  
  return nil;
}

#pragma mark -

- (NSArray *)identities {
  NSDictionary *query = @{
                          (id)kSecClass:(id)kSecClassIdentity,
                          (id)kSecMatchLimit:(id)kSecMatchLimitAll,
                          (id)kSecReturnRef:(id)kCFBooleanTrue
                          };
  
  CFArrayRef identities;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&identities);
  
  if (status != noErr) {
    return nil;
  }
  
  NSMutableArray *result = [NSMutableArray arrayWithArray:(__bridge_transfer NSArray *) identities];
  
  // Allow only identities with APNS certificate
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^(id object, NSDictionary *bindings) {
    SecIdentityRef identity = (__bridge SecIdentityRef) object;
    APNSSecIdentityType type = APNSSecIdentityGetType(identity);
    BOOL isValid = (type != APNSSecIdentityTypeInvalid);
    return isValid;
  }];
  [result filterUsingPredicate:predicate];
  
  // Sort identities by name
  NSComparator comparator = (NSComparator) ^(SecIdentityRef id1, SecIdentityRef id2) {
    SecCertificateRef cert1;
    SecIdentityCopyCertificate(id1, &cert1);
    NSString *name1 = (__bridge_transfer NSString*)SecCertificateCopyShortDescription(NULL, cert1, NULL);
    CFRelease(cert1);
    
    SecCertificateRef cert2;
    SecIdentityCopyCertificate(id2, &cert2);
    NSString *name2 = (__bridge_transfer NSString*)SecCertificateCopyShortDescription(NULL, cert2, NULL);
    CFRelease(cert2);
    
    return [name1 compare:name2];
  };
  [result sortUsingComparator:comparator];
  
  return result;
}

- (NSString *)preparedToken {
  NSString *token = self.tokenTextField.stringValue;
  
  // Clean token
  NSCharacterSet *removeCharacterSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
  token = [[token componentsSeparatedByCharactersInSet:removeCharacterSet] componentsJoinedByString:@""];
  token = [token lowercaseString];
  
  // Split into chunks
  static NSUInteger const tokenChunkCount = 8;
  static NSUInteger const tokenChunkSize = 8;
  
  NSUInteger characterCount = tokenChunkCount * tokenChunkSize;
  NSUInteger spacesCount = tokenChunkCount - 1;
  
  // If shorter than the expected size, split and pad with spaces
  if ([token length] < characterCount + spacesCount) {
    NSMutableArray *chunks = [[NSMutableArray alloc] initWithCapacity:tokenChunkCount];
    
    for (NSUInteger i = 0; i < tokenChunkCount; ++i) {
      NSRange range = NSMakeRange(i * tokenChunkSize, tokenChunkSize);
      if (range.location + range.length <= [token length]) {
        [chunks addObject:[token substringWithRange:range]];
      }
    }
    
    token = [chunks componentsJoinedByString:@" "];
  }
  
  return token;
}

#pragma mark -

- (NSString *)identityName {
  if (self.APNS.identity == NULL)
    return @"Choose an identity";
  else {
    SecCertificateRef cert = NULL;
    if (noErr == SecIdentityCopyCertificate(self.APNS.identity, &cert)) {
      CFStringRef commonName = NULL;
      SecCertificateCopyCommonName(cert, &commonName);
      CFRelease(cert);
      
      return (__bridge_transfer NSString *)commonName;
    }
  }
  return @"";
}

- (APNSDocument *)document {
  return self.representedObject;
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
  if (anItem.action == @selector(exportIdentity:)) {
    return (self.APNS.identity != NULL);
  }
  
  return NO;
}

#pragma mark - NSTextDelegate

- (void)textDidChange:(NSNotification *)notification {
  [self.document setPayload:self.fragaria.string];
}

#pragma mark - NSControlSubclassNotifications

- (void)controlTextDidChange:(NSNotification *)notification {
  [self.document setToken:self.tokenTextField.stringValue];
}

#pragma mark - NSTextViewDelegate

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)view {
  return self.document.undoManager;
}

#pragma mark - APNSDevicesViewControllerDelegate

- (void)deviceViewController:(APNSDevicesViewController *)viewController didSelectDevice:(APNSServiceDevice *)device {
  self.tokenTextField.stringValue = device.token;
  
  [self.devicesPopover close];
  
  [self.document setToken:self.tokenTextField.stringValue];
}

#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)notification {
  self.devicesPopover.contentViewController = nil;
  self.devicesPopover = nil;
}

@end
