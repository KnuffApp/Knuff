//
//  Copyright © 2014 Yuri Kotov
//

#import "SBIdentityTypeDetection.h"

static NSString * const CertExtensionProductionAPNS     = @"1.2.840.113635.100.6.3.2";
static NSString * const CertExtensionDevelopmentAPNS    = @"1.2.840.113635.100.6.3.1";

SBIdentityType SBSecIdentityGetType(SecIdentityRef identity) {

	SecCertificateRef certificate;
	SecIdentityCopyCertificate(identity, &certificate);
	NSArray *keys = @[CertExtensionProductionAPNS, CertExtensionDevelopmentAPNS];
	NSDictionary *values = (__bridge_transfer NSDictionary *)
		SecCertificateCopyValues(certificate, (__bridge CFArrayRef)keys, NULL);
	CFRelease(certificate);

	if (values[CertExtensionDevelopmentAPNS]) {
		return SBIdentityTypeDevelopment;
	} else if (values[CertExtensionProductionAPNS]) {
		return SBIdentityTypeProduction;
	} else {
		return SBIdentityTypeInvalid;
	}
}