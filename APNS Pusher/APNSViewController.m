//
//  APNSViewController.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 14/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSViewController.h"
#import <MGSFragaria/MGSFragaria.h>

#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <Security/Security.h>

#import "APNSSecIdentityType.h"
#import "SBAPNS.h"

NSString * const APNSViewControllerDefaultPayload = @"{\n\t\"aps\":{\n\t\t\"alert\":\"Test\",\n\t\t\"sound\":\"default\",\n\t\t\"badge\":0\n\t}\n}";

@interface APNSViewController () <NSTextDelegate>
@property (nonatomic, strong) SBAPNS *APNS;

@property (nonatomic, assign, readonly) NSString *identityName;

@property (weak) IBOutlet NSTextField *tokenTextField;

@property (nonatomic, strong, readonly) NSDictionary *payload;

@property (nonatomic, assign, readonly) NSString *alert;
@property (nonatomic, assign, readonly) NSString *sound;
@property (nonatomic, assign, readonly) NSString *badge;
@property (nonatomic, assign, readonly) NSString *category;
@property (nonatomic, assign, readonly) BOOL contentAvailable;

@property (weak) IBOutlet NSView *fragariaContentView;
@property (nonatomic, strong) MGSFragaria *fragaria;

@end

@implementation APNSViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self APNS];
  
  [self.fragaria embedInView:self.fragariaContentView];
}

- (IBAction)test:(id)sender {
  NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
  NSViewController *viewController = [storyboard instantiateControllerWithIdentifier:@"Devices View Controller"];
  
  NSPopover *popover = [[NSPopover alloc] init];
  popover.contentViewController = viewController;
  
  popover.animates = YES;
  popover.behavior = NSPopoverBehaviorTransient;
  [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
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
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = @"Missing identity";
    alert.informativeText = @"You have not choosen an identity for signing the notification.";
    
    [alert beginSheetModalForWindow:self.windowController.window completionHandler:nil];
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

#pragma mark -

- (MGSFragaria *)fragaria {
  if (!_fragaria) {
    _fragaria = [[MGSFragaria alloc] init];
    [[MGSFragariaPreferences sharedInstance] revertToStandardSettings:nil];
    
    [_fragaria setObject:self forKey:MGSFODelegate];
    [_fragaria setObject:@"JavaScript" forKey:MGSFOSyntaxDefinitionName];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self willChangeValueForKey:@"payload"];
      [_fragaria setString:APNSViewControllerDefaultPayload];
      [self didChangeValueForKey:@"payload"];
    });
  }
  return _fragaria;
}

- (NSDictionary *)payload {
  NSData *data = [self.fragaria.string dataUsingEncoding:NSUTF8StringEncoding];
  
  if (data) {
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
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
}

@end
