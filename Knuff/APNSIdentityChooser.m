//
//  APNSIdentityChooser.m
//  Knuff
//
//  Created by Joel Ekström on 2016-09-16.
//  Copyright © 2016 Bowtie. All rights reserved.
//

#import "APNSIdentityChooser.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <Security/Security.h>
#import "Constants.h"

@interface APNSIdentityChooser()

@property (nonatomic, copy) void (^completionBlock)(APNSIdentity *);

@end

@implementation APNSIdentityChooser

- (void)displayWithWindow:(NSWindow *)window completion:(void(^)(APNSIdentity *selectedIdentity))completionBlock
{
  self.completionBlock = completionBlock;
  SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
  [panel setAlternateButtonTitle:@"Cancel"];

  [panel beginSheetForWindow:window
               modalDelegate:self
              didEndSelector:@selector(chooseIdentityPanelDidEnd:returnCode:contextInfo:)
                 contextInfo:nil
                  identities:[self identityRefs]
                     message:@"Choose the identity to use for delivering notifications: \n(Issued by Apple in the Provisioning Portal)"];
}

- (void)chooseIdentityPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSFileHandlingPanelOKButton) {
    if (self.completionBlock) {
      SecIdentityRef identityRef = [SFChooseIdentityPanel sharedChooseIdentityPanel].identity;
      APNSIdentity *identity = [[APNSIdentity alloc] initWithSecIdentityRef:identityRef];
      self.completionBlock(identity);
    }
  } else if (self.completionBlock) {
    self.completionBlock(nil);
  }
}

- (NSArray *)identityRefs {
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
    APNSSecIdentityType type = APNSSecIdentityGetType(identity, NULL);
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

@end
