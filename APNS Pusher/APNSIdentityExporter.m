//
//  APNSIdentityExporter.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 28/04/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSidentityExporter.h"

@implementation APNSIdentityExporter

+ (void)exportIdentity:(SecIdentityRef)identity withPanelWindow:(NSWindow *)window {
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
    
    if (noErr == SecItemExport(identity,
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

@end
