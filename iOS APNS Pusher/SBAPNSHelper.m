//
//  SBAPNSHelper.m
//  APNS Pusher
//
//  Created by Prince on 13/6/30.
//  Copyright (c) 2013年 Doubleint. All rights reserved.
//

#import "SBAPNSHelper.h"
#import <CoreFoundation/CoreFoundation.h>
#import "SBAPNS.h"

@interface SBAPNSHelper ()
@property (nonatomic, strong) SBAPNS *APNS;
@end

@implementation SBAPNSHelper

+ (SBAPNSHelper *)sharedAPNSHelper {
    static SBAPNSHelper *_sharedinstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        _sharedinstance = [[SBAPNSHelper alloc] init];
        
    });
    
    return _sharedinstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self APNS];
    [self choiceCertificate];
}

- (SBAPNS *)APNS {
    if (!_APNS) {
        _APNS = [SBAPNS new];
        [_APNS setErrorBlock:^(uint8_t status, NSString *description, uint32_t identifier) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error delivering notification" message:[NSString stringWithFormat:@"There was an error delivering the notificaton %d: %@", identifier, description] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [alert show];
        }];
    }
    return _APNS;
}

- (void)choiceCertificate {
    NSString *PKCS12Path = [[NSBundle mainBundle] pathForResource:@"apns" ofType:@"p12"];
    NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:PKCS12Path];
    CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;
    CFStringRef password = CFSTR("1234");
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    CFDictionaryRef optionsDictionary = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus status = SecPKCS12Import(inPKCS12Data, optionsDictionary, &items);

    CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
    SecIdentityRef ificateRef = (SecIdentityRef)CFDictionaryGetValue(identityDict, kSecImportItemIdentity);
    [self.APNS setIdentity:ificateRef];
}

#pragma mark - public

- (NSString *)identityName {

	if (self.APNS.identity == NULL)
		return @"Choose an identity";
	else {
        SecCertificateRef cert = NULL;
        if (noErr == SecIdentityCopyCertificate(self.APNS.identity, &cert)) {
            
            CFStringRef summary = NULL;
            summary = SecCertificateCopySubjectSummary(cert);

            CFRelease(cert);
            return (__bridge_transfer NSString *)summary;
        }
    }
    return @"";
}

- (void)pushPayload:(NSDictionary *)payload withToken:(NSString *)token andSandbox:(BOOL)sandbox{
    
    if (!self.APNS.ready) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error delivering notification" message:@"Attempting to connect while connected or accepting connections,please try again later." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    if (self.APNS.identity != NULL){
        self.APNS.sandbox = sandbox;
        [self.APNS pushPayload:payload withToken:token];
    }
}

@end
