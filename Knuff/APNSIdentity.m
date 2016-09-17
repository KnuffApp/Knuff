//
//  APNSIdentity.m
//  Knuff
//
//  Created by Joel Ekström on 2016-09-17.
//  Copyright © 2016 Bowtie. All rights reserved.
//

#import "APNSIdentity.h"
#import <Security/Security.h>

NSString * const APNSDefaultIdentityDidChangeNotification = @"APNSDefaultIdentityDidChangeNotification";

@interface APNSIdentity() {
  SecIdentityRef _identityRef;
}

@end

@implementation APNSIdentity

- (instancetype)initWithSecIdentityRef:(SecIdentityRef)ref
{
  if (ref == NULL) {
    return nil;
  }

  if (self = [super init]) {
    _identityRef = ref;
    CFRetain(_identityRef);
  }
  return self;
}

- (void)dealloc
{
  CFRelease(_identityRef);
}

- (NSString *)displayName
{
  SecCertificateRef cert = NULL;
  if (noErr == SecIdentityCopyCertificate(_identityRef, &cert)) {
    CFStringRef commonName = NULL;
    SecCertificateCopyCommonName(cert, &commonName);
    CFRelease(cert);
    return (__bridge_transfer NSString *)commonName;
  }
  return @"";
}

#pragma mark - Types

- (APNSSecIdentityType)type
{
  return APNSSecIdentityGetType(_identityRef, nil);
}

- (NSArray<NSString *> *)topics
{
  NSArray *topics = nil;
  APNSSecIdentityGetType(_identityRef, &topics);
  return topics;
}

#pragma mark -

- (NSURLCredential *)credecential
{
  SecCertificateRef certificate;
  SecIdentityCopyCertificate(_identityRef, &certificate);
  return [[NSURLCredential alloc] initWithIdentity:_identityRef
                                      certificates:@[(__bridge_transfer id)certificate]
                                       persistence:NSURLCredentialPersistenceForSession];
}

#pragma mark - Exporting

- (void)exportWithPanelWindow:(NSWindow *)window {
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

  if (noErr == SecItemExport(_identityRef,
                             kSecFormatPKCS12,
                             0,
                             &keyParams,
                             &data)) {

    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setPrompt:@"Export"];
    [panel setNameFieldLabel:@"Export As:"];
    [panel setNameFieldStringValue:@"cert.pem"];

    [panel beginSheetModalForWindow:window
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

#pragma mark - Default Identity

static APNSIdentity *defaultIdentity = nil;

+ (instancetype)defaultIdentity
{
  return defaultIdentity;
}

+ (void)setDefaultIdentity:(APNSIdentity *)identity
{
  defaultIdentity = identity;
  [[NSNotificationCenter defaultCenter] postNotificationName:APNSDefaultIdentityDidChangeNotification object:nil];
}

@end
