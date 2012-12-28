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
	if (self.APNS.identity != NULL)
      [self.APNS pushPayload:self.payload withToken:self.tokenTextField.stringValue];
	else {
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
    
    SecItemImportExportKeyParameters keyParams = {
      SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION,
      0,
      (__bridge CFStringRef)@"lol",
      NULL,
      NULL,
      NULL,
      NULL,
      (__bridge CFArrayRef)@[@(CSSM_KEYATTR_PERMANENT)]
    };
    
    if (noErr == SecItemExport(
                               self.APNS.identity,
                               kSecFormatPKCS12,
                               0,
                               &keyParams,
                               &data)) {
      
      [(__bridge NSData *)data writeToFile:@"/tmp/lol.p12" atomically:YES];
      NSTask *task = [NSTask new];
      [task setLaunchPath:@"/bin/sh"];
      [task setArguments:@[@"-c", @"/usr/bin/openssl pkcs12 -in /tmp/lol.p12 -out /Users/simon/Desktop/certificate.cer -nodes"]];
      
      
      NSPipe *pipe = [NSPipe pipe];
      [task setStandardInput:pipe];
     
      [task launch];
      
            [pipe.fileHandleForWriting writeData:[@"lol" dataUsingEncoding:NSUTF8StringEncoding]];
      
    }
  }
}

#pragma mark -

- (NSArray *)identities {
  NSDictionary *query = @{
    (id)kSecClass:(id)kSecClassIdentity,
    (id)kSecMatchLimit:(id)kSecMatchLimitAll,
    (id)kSecReturnRef:(id)kCFBooleanTrue
  };
  
	NSArray *result = @[];
	CFArrayRef identities = NULL;
	
	if (noErr == SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&identities))
		result = (__bridge_transfer NSArray*)identities;
	
	return result;
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
    [_APNS setErrorBlock:^(uint8_t status, NSString *description, uint32_t identifier) {
      NSAlert *alert = [NSAlert alertWithMessageText:@"Error delivering notification"
                                       defaultButton:@"OK"
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:@"There was an error delivering the notificaton %d: %@", identifier, description];
      
      [alert beginSheetModalForWindow:self.window
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
