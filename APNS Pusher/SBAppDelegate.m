//
//  PBAppDelegate.m
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-12.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import "SBAppDelegate.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <Security/Security.h>
#import "SBAPNS.h"
#import <MGSFragaria/MGSFragaria.h>
#import "SBNetServiceSearcher.h"

static NSString * const CertExtensionDevelopmentAPNS    = @"1.2.840.113635.100.6.3.1";
static NSString * const CertExtensionProductionAPNS     = @"1.2.840.113635.100.6.3.2";

NSString * const kPBAppDelegateDefaultPayload = @"{\n\t\"aps\":{\n\t\t\"alert\":\"Test\",\n\t\t\"sound\":\"default\",\n\t\t\"badge\":0\n\t}\n}";

@interface SBAppDelegate ()
- (NSArray *)identities;
@property (nonatomic, strong) MGSFragaria *fragaria;
@property (nonatomic, strong, readonly) NSDictionary *payload;
@property (nonatomic, strong) SBAPNS *APNS;
@property (nonatomic, strong) SBNetServiceSearcher *searcher;
@end

@implementation SBAppDelegate

@synthesize window = _window;
@dynamic identityName;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self APNS];
  [self searcher];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  [self.window makeKeyAndOrderFront:self];
  return NO;
}

- (void)awakeFromNib {
  [super awakeFromNib];
  [self.fragaria embedInView:self.containerView];
}

#pragma mark Actions

- (IBAction)chooseIdentity:(id)sender {
	SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
	[panel setAlternateButtonTitle:@"Cancel"];
	
	[panel beginSheetForWindow:self.window
							 modalDelegate:self
							didEndSelector:@selector(chooseIdentityPanelDidEnd:returnCode:contextInfo:)
								 contextInfo:nil
									identities:[self identities]
										 message:@"Choose the identity to use for delivering notifications: \n(Issued by Apple in the Provisioning Portal)"];
}

- (IBAction)chooseNetServiceDevice:(id)sender {
  NSPopUpButton *button = sender;
  
  NSInteger index = [button indexOfSelectedItem];
  NSNetService *netService = [self.searcher.availableNetServices objectAtIndex:index];
  NSData *data = [[NSNetService dictionaryFromTXTRecordData:netService.TXTRecordData] objectForKey:@"token"];
  NSString *token = [data.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
  
  [self.tokenTextField setStringValue:token];
}

-(void)chooseIdentityPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSFileHandlingPanelOKButton) {		
		[self.APNS setIdentity:[SFChooseIdentityPanel sharedChooseIdentityPanel].identity];

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
		NSAlert *alert = [NSAlert alertWithMessageText:@"Missing identity"
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"You have not choosen an identity for signing the notification."];
    
		[alert beginSheetModalForWindow:self.window
											modalDelegate:self
										 didEndSelector:nil
												contextInfo:nil];
	}
}

- (IBAction)exportIdentity:(id)sender {
  if (self.APNS.identity != NULL) {
    CFDataRef data = NULL;
    
    // Generate a random passphrase and filename
    NSString *passphrase = [[NSUUID UUID] UUIDString];
    NSString *PKCS12FileName = [[NSUUID UUID] UUIDString];
    
    // Export to PKCS12
    SecItemImportExportKeyParameters keyParams = {
      SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION,
      0,
      (__bridge CFStringRef)passphrase,
      NULL,
      NULL,
      NULL,
      NULL,
      (__bridge CFArrayRef)@[@(CSSM_KEYATTR_PERMANENT)]
    };
    
    if (noErr == SecItemExport(self.APNS.identity,
                               kSecFormatPKCS12,
                               0,
                               &keyParams,
                               &data)) {
      
      NSSavePanel *panel = [NSSavePanel savePanel];
      [panel setPrompt:@"Export"];
      [panel setNameFieldLabel:@"Export As:"];
      [panel setNameFieldStringValue:@"cert.pem"];
      
      [panel beginSheetModalForWindow:self.window
                    completionHandler:^(NSInteger result) {
                      if (result == NSFileHandlingPanelCancelButton)
                        return;
                      
                      // Write to temp file
                      NSURL *tempURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                      tempURL = [tempURL URLByAppendingPathComponent:PKCS12FileName];
                      
                      [(__bridge NSData *)data writeToURL:tempURL atomically:YES];
                      
                      // convert with openssl to pem
                      NSTask *task = [NSTask new];
                      [task setLaunchPath:@"/bin/sh"];
                      [task setArguments:@[
                       @"-c",
                       [NSString stringWithFormat:@"/usr/bin/openssl pkcs12 -in %@ -out %@ -nodes", tempURL.path, panel.URL.path]
                       ]];
                      
                      // Remove temp file on completion
                      [task setTerminationHandler:^(NSTask *task) {
                        [[NSFileManager defaultManager] removeItemAtURL:tempURL error:NULL];
                      }];
                      
                      NSPipe *pipe = [NSPipe pipe];
                      [pipe.fileHandleForWriting writeData:[[NSString stringWithFormat:@"%@\n", passphrase] dataUsingEncoding:NSUTF8StringEncoding]];
                      [task setStandardInput:pipe];

                      [task launch];
                    }];
    }
  }
}

#pragma mark -

- (NSArray *)identities {
  NSMutableArray *result;

  NSDictionary *query = @{
    (id)kSecClass:(id)kSecClassIdentity,
    (id)kSecMatchLimit:(id)kSecMatchLimitAll,
    (id)kSecReturnRef:(id)kCFBooleanTrue
  };

  CFArrayRef identities;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&identities);
  if (status != noErr) return nil;
  result = [(__bridge NSArray *) identities mutableCopy];
  CFRelease(identities);

  // Allow only identities with APNS certificate
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^(id object, NSDictionary *bindings) {
    SecIdentityRef identity = (__bridge SecIdentityRef) object;

    SecCertificateRef certificate;
    SecIdentityCopyCertificate(identity, &certificate);
    NSArray *keys = @[CertExtensionDevelopmentAPNS, CertExtensionProductionAPNS];
    CFDictionaryRef values = SecCertificateCopyValues(certificate, (__bridge CFArrayRef)keys, NULL);
    BOOL isValid = 0 < CFDictionaryGetCount(values);
    CFRelease(values);
    CFRelease(certificate);
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

#pragma mark - Properties

- (NSString *)alertString {
  return [self.payload valueForKeyPath:@"aps.alert"];
}

- (NSString *)soundString {
  return [self.payload valueForKeyPath:@"aps.sound"];
}

- (NSString *)badgeString {
  return [NSString stringWithFormat:@"%@", [self.payload valueForKeyPath:@"aps.badge"]];
}

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

- (MGSFragaria *)fragaria {
  if (!_fragaria) {
    _fragaria = [[MGSFragaria alloc] init];
    [[MGSFragariaPreferences sharedInstance] revertToStandardSettings:nil];
    
    [_fragaria setObject:self forKey:MGSFODelegate];
    [_fragaria setObject:@"JavaScript" forKey:MGSFOSyntaxDefinitionName];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self willChangeValueForKey:@"payload"];
      [_fragaria setString:kPBAppDelegateDefaultPayload];
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

- (SBAPNS *)APNS {
  if (!_APNS) {
    _APNS = [SBAPNS new];
    __weak SBAppDelegate *weakSelf = self;
    [_APNS setErrorBlock:^(uint8_t status, NSString *description, uint32_t identifier) {
      NSAlert *alert = [NSAlert alertWithMessageText:@"Error delivering notification"
                                       defaultButton:@"OK"
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:@"There was an error delivering the notificaton %d: %@", identifier, description];
      
      [alert beginSheetModalForWindow:weakSelf.window
                        modalDelegate:nil
                       didEndSelector:nil
                          contextInfo:nil];
    }];
  }
  return _APNS;
}

- (SBNetServiceSearcher *)searcher {
  if (!_searcher) {
    _searcher = [SBNetServiceSearcher new];
    [_searcher setSearching:YES];
  }
  return _searcher;
}

#pragma mark - KVO Keys

+ (BOOL)automaticallyNotifiesObserversOfPayload {
  return NO;
}

+ (NSSet *)keyPathsForValuesAffectingAlertString {
  return [NSSet setWithObject:@"payload"];
}

+ (NSSet *)keyPathsForValuesAffectingSoundString {
  return [NSSet setWithObject:@"payload"];
}

+ (NSSet *)keyPathsForValuesAffectingBadgeString {
  return [NSSet setWithObject:@"payload"];
}

#pragma mark - NSTextDelegate

- (void)textDidChange:(NSNotification *)notification {
  [self willChangeValueForKey:@"payload"];
  [self didChangeValueForKey:@"payload"];
}

@end
