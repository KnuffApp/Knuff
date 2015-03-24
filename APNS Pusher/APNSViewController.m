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

#import "APNSTextStorageJSONHighlighter.h"

#import "FBKVOController.h"

@interface APNSViewController () <NSTextDelegate, APNSDevicesViewControllerDelegate, NSPopoverDelegate>
@property (nonatomic, strong) FBKVOController *KVOController;

@property (nonatomic, strong) SBAPNS *APNS;
@property (nonatomic, strong) APNSKnuffService *knuffService;

@property (nonatomic, assign, readonly) NSString *identityName;

@property (weak) IBOutlet NSTextField *tokenTextField;

@property (nonatomic, strong, readonly) NSDictionary *payload;

@property (nonatomic, assign, readonly) NSString *alert;
@property (nonatomic, assign, readonly) NSString *sound;
@property (nonatomic, assign, readonly) NSString *badge;
@property (nonatomic, assign, readonly) NSString *category;
@property (nonatomic, assign, readonly) BOOL contentAvailable;

@property (strong) IBOutlet NSTextView *textView;
@property (nonatomic, strong) APNSTextStorageJSONHighlighter *JSONHighlighter;

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
  
  self.textView.textStorage.delegate = self.JSONHighlighter;
  
  self.textView.automaticQuoteSubstitutionEnabled = NO;
  
  [self APNS];
  
  [APNSServiceBrowser browser].searching = YES;
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
  
  [panel beginSheetForWindow:self.windowController.window
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
      
      [alert beginSheetModalForWindow:weakSelf.windowController.window completionHandler:nil];
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

- (APNSTextStorageJSONHighlighter *)JSONHighlighter {
  if (!_JSONHighlighter) {
    _JSONHighlighter = [APNSTextStorageJSONHighlighter new];
  }
  return _JSONHighlighter;
}

#pragma mark -

- (void)setWindowController:(NSWindowController *)windowController {
  [self.KVOController unobserve:_windowController];

  _windowController = windowController;
  
  [self.KVOController observe:windowController
                      keyPath:@"document.token"
                      options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                        block:^(APNSViewController *observer, NSWindowController *object, NSDictionary *change) {
                          APNSDocument *document = object.document;
                          
                          if (document.token) {
                            [observer.tokenTextField setStringValue:document.token];
                          } else {
                            [observer.tokenTextField setStringValue:@""];
                          }
                        }];
  
  [self willChangeValueForKey:@"payload"];
  self.textView.string = ((APNSDocument *)windowController.document).payload;
  [self didChangeValueForKey:@"payload"];
}

#pragma mark -

- (NSDictionary *)payload {
  NSData *data = [self.textView.string dataUsingEncoding:NSUTF8StringEncoding];
  
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


- (NSString *)alert {
  return [self.payload valueForKeyPath:@"aps.alert"];
}

- (NSString *)sound {
  return [self.payload valueForKeyPath:@"aps.sound"];
}

- (NSString *)badge {
  NSNumber *badge = [self.payload valueForKeyPath:@"aps.badge"];
  if ([badge isKindOfClass:[NSNumber class]]) {
    return badge.stringValue;
  }
  return nil;
}

- (NSString *)category {
  return [self.payload valueForKeyPath:@"aps.category"];
}

- (BOOL)contentAvailable {
  NSNumber *contentAvailable = [self.payload valueForKeyPath:@"aps.content-available"];
  if ([contentAvailable isKindOfClass:[NSNumber class]]) {
    return contentAvailable.boolValue;
  }
  return NO;
}

#pragma mark - KVO

+ (BOOL)automaticallyNotifiesObserversOfPayload {
  return NO;
}

+ (NSSet *)keyPathsForValuesAffectingAlert {
  return [NSSet setWithObject:@"payload"];
}

+ (NSSet *)keyPathsForValuesAffectingSound {
  return [NSSet setWithObject:@"payload"];
}

+ (NSSet *)keyPathsForValuesAffectingBadge {
  return [NSSet setWithObject:@"payload"];
}

+ (NSSet *)keyPathsForValuesAffectingCategory {
  return [NSSet setWithObject:@"payload"];
}

+ (NSSet *)keyPathsForValuesAffectingContentAvailable {
  return [NSSet setWithObject:@"payload"];
}

#pragma mark - NSTextDelegate

- (void)textDidChange:(NSNotification *)notification {
  [self willChangeValueForKey:@"payload"];
  [self didChangeValueForKey:@"payload"];
  
  APNSDocument *document = self.windowController.document;

  [document setPayload:self.textView.string];
}

#pragma mark - NSControlSubclassNotifications

- (void)controlTextDidChange:(NSNotification *)notification {
  APNSDocument *document = self.windowController.document;
  
  [document setToken:self.tokenTextField.stringValue];
}

#pragma mark - NSTextViewDelegate

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)view {
  APNSDocument *document = self.windowController.document;
  return document.undoManager;
}

#pragma mark - APNSDevicesViewControllerDelegate

- (void)deviceViewController:(APNSDevicesViewController *)viewController didSelectDevice:(APNSServiceDevice *)device {
  self.tokenTextField.stringValue = device.token;
  
  [self.devicesPopover close];
  
  APNSDocument *document = self.windowController.document;
  [document setToken:self.tokenTextField.stringValue];
}

#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)notification {
  self.devicesPopover.contentViewController = nil;
  self.devicesPopover = nil;
}

@end
