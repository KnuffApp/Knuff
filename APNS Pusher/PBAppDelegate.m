//
//  PBAppDelegate.m
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-12.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import "PBAppDelegate.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <Security/Security.h>
#import "X509Certificate.h"
#import "APNS.h"

@interface PBAppDelegate ()
- (NSArray *)identities;
@end

@implementation PBAppDelegate

@synthesize window = _window;
@dynamic identityName;
@dynamic sandbox;
@synthesize tokenTextField = _tokenTextField;
@synthesize alertTextField = _alertTextField;
@synthesize soundTextField = _soundTextField;
@synthesize badgeTextField = _badgeTextField;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[APNS sharedAPNS] setErrorBlock:^(uint8_t status, NSString *description, uint32_t identifier) {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Error delivering notification" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error delivering the notificaton %d: %@", identifier, description];
		[alert beginSheetModalForWindow:self.window
											modalDelegate:nil
										 didEndSelector:nil
												contextInfo:nil];
	}];
}

#pragma mark Actions

- (IBAction)chooseIdentity:(id)sender {
	SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
	[panel setAlternateButtonTitle:@"Cancel"];
//	[panel setPolicies:d SecPolicyRef
	
	[panel beginSheetForWindow:self.window
							 modalDelegate:self
							didEndSelector:@selector(chooseIdentityPanelDidEnd:returnCode:contextInfo:)
								 contextInfo:nil
									identities:[self identities]
										 message:@"Choose the identity to use for delivering notifications: \n(Issued by Apple in the Provisioning Portal)"];
}

-(void)chooseIdentityPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSFileHandlingPanelOKButton) {		
		[[APNS sharedAPNS] setIdentity:(SecIdentityRef)CFRetain([SFChooseIdentityPanel sharedChooseIdentityPanel].identity)];

		// KVO trigger
		[self willChangeValueForKey:@"identityName"];
		[self didChangeValueForKey:@"identityName"];
	}
}

- (IBAction)push:(id)sender {
	if ([APNS sharedAPNS].identity != NULL)
		[[APNS sharedAPNS] pushWithToken:[_tokenTextField stringValue] alert:[_alertTextField stringValue] sound:[_soundTextField stringValue] badge:[_badgeTextField integerValue]];
	else {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Missing identity" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You have not choosen an identity for signing the notification."];
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
		result = [NSArray arrayWithArray:(__bridge id)identities];
	else
		result = [NSArray array];
	
	if (identities != NULL)
		CFRelease(identities);
	
	return result;
}

#pragma mark - Properties

- (NSString *)identityName {	
	if ([APNS sharedAPNS].identity == NULL)
		return @"Choose an identity";
	else
		return [[[X509Certificate extractCertDictFromIdentity:[APNS sharedAPNS].identity] objectForKey:@"Subject"] objectForKey:@"CommonName"];
}

- (BOOL)isSandbox {
	return [APNS sharedAPNS].isSandbox;
}

- (void)setSandbox:(BOOL)sandbox {
	[[APNS sharedAPNS] setSandbox:sandbox];
}

@end
