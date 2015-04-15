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

#import "FBKVOController.h"

#import <MGSFragaria/MGSFragaria.h>
#import "pop.h"

@interface APNSViewController () <NSTextDelegate, APNSDevicesViewControllerDelegate, NSPopoverDelegate, NSTextViewDelegate>
@property (nonatomic, strong) FBKVOController *KVOController;

@property (nonatomic, strong) SBAPNS *APNS;
@property (nonatomic, strong) APNSKnuffService *knuffService;

@property (nonatomic, assign, readonly) NSString *identityName;

@property (nonatomic, assign) BOOL showDevices;
@property (weak) IBOutlet NSTextField *tokenTextField;
@property (weak) IBOutlet NSButton *devicesButton;

@property (nonatomic, strong, readonly) NSDictionary *payload;

@property (weak) IBOutlet NSView *customView;
@property (nonatomic, strong) MGSFragaria *fragaria;

@property (nonatomic, strong) NSPopover *devicesPopover;
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
  
  __block BOOL isInitial = YES;
  [self.KVOController observe:[APNSServiceBrowser browser]
                      keyPath:@"devices"
                      options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                        block:^(APNSDevicesViewController *observer, APNSServiceBrowser* object, NSDictionary *change) {
                          [self devicesDidChange:isInitial];
                          isInitial = NO;
  }];
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

- (IBAction)changeMode:(NSSegmentedControl *)sender {
  POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlphaValue];

  animation.toValue = (sender.selectedSegment == 1) ? @(0):@(1);

  [self.tokenTextField pop_addAnimation:animation forKey:nil];
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

-(void)chooseIdentityPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSFileHandlingPanelOKButton) {
    SecIdentityRef identity = [SFChooseIdentityPanel sharedChooseIdentityPanel].identity;
    [self.APNS setIdentity:identity];
    
    // KVO trigger
    [self willChangeValueForKey:@"identityName"];
    [self didChangeValueForKey:@"identityName"];
  }
}

- (IBAction)push:(id)sender {
  if (self.APNS.identity != NULL) {
    NSString *token = [self preparedToken];
    [self.APNS pushPayload:self.payload withToken:token];
  } else {
  [self.knuffService pushPayload:self.payload toToken:[self preparedToken] withPriority:10 expiry:0];
    
//    NSAlert *alert = [NSAlert new];
//    [alert addButtonWithTitle:@"OK"];
//    alert.messageText = @"Missing identity";
//    alert.informativeText = @"You have not choosen an identity for signing the notification.";
//    
//    [alert beginSheetModalForWindow:self.windowController.window completionHandler:nil];
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
    textFieldRect.size.width = self.view.bounds.size.width - textFieldRect.origin.x - 20;
    
    changed = YES;
  }
  // Show
  else if (!self.showDevices && browser.devices.count > 0) {
    devicesButtonAlpha = 1;
    textFieldRect.size.width = self.view.bounds.size.width - textFieldRect.origin.x - 20 - self.devicesButton.bounds.size.width - 8;

    changed = YES;
  }
  
  if (changed) {
    self.showDevices = !self.showDevices;
    
    if (initial) {
      self.devicesButton.alphaValue = devicesButtonAlpha;
      self.tokenTextField.frame = textFieldRect;
    } else {
      POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlphaValue];
      animation.toValue = @(devicesButtonAlpha);
      
      [self.devicesButton pop_addAnimation:animation forKey:nil];
      
      animation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
      animation.toValue = [NSValue valueWithRect:textFieldRect];
      
      [self.tokenTextField pop_addAnimation:animation forKey:nil];
    }
  }
}

#pragma mark -

- (SBAPNS *)APNS {
  if (!_APNS) {
    _APNS = [SBAPNS new];
    __weak APNSViewController *weakSelf = self;
    [_APNS setErrorBlock:^(uint8_t status, NSString *description, uint32_t identifier) {
      
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
  
  // This should be done in -viewDidLoad, but we have no document there, and no undo manager
  [self.fragaria embedInView:self.customView];
  
  [self willChangeValueForKey:@"payload"];
  [self.fragaria setString:representedObject.payload];
  [self didChangeValueForKey:@"payload"];
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

- (void)dealloc {
  
}

#pragma mark - KVO

+ (BOOL)automaticallyNotifiesObserversOfPayload {
  return NO;
}

#pragma mark - NSTextDelegate

- (void)textDidChange:(NSNotification *)notification {
  [self willChangeValueForKey:@"payload"];
  [self didChangeValueForKey:@"payload"];
  
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
