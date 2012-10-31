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
#import "X509Certificate.h"
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
		[self.APNS setIdentity:(SecIdentityRef)CFRetain([SFChooseIdentityPanel sharedChooseIdentityPanel].identity)];

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

#pragma mark -

- (NSArray *)identities {
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
												 kSecClassIdentity, kSecClass, 
												 kSecMatchLimitAll, kSecMatchLimit, 
												 kCFBooleanTrue, kSecReturnRef, nil];
	
	OSStatus err;
	NSArray *result;
	CFArrayRef identities;
	
	identities = NULL;
	
	err = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&identities);
	
	if (err == noErr)
		result = (__bridge id)identities;
	else
		result = @[];
	
	if (identities != NULL)
		CFRelease(identities);
	
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
	else
		return [[[X509Certificate extractCertDictFromIdentity:self.APNS.identity] objectForKey:X509_SUBJECT] objectForKey:X509_COMMON_NAME];
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
