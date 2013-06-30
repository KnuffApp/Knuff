//
//  SBAppDelegate.m
//  iOS APNS Pusher
//
//  Created by Prince on 13/6/30.
//  Copyright (c) 2013年 Doubleint. All rights reserved.
//

#import "SBAppDelegate.h"
#import <CoreFoundation/CoreFoundation.h>
#import "SBAPNS.h"

#import "SBViewController.h"

@interface SBAppDelegate ()
@property (nonatomic, strong, readonly) NSDictionary *payload;
@property (nonatomic, strong) SBAPNS *APNS;
@end

@implementation SBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[SBViewController alloc] initWithNibName:@"SBViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    [self APNS];
    [self choiceCertificate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushPayloadFromNotification:) name:kPushNotificationKey object:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"apns" ofType:@"p12"];
    NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:thePath];
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

- (void)pushPayloadFromNotification:(NSNotification *)notification {

    NSDictionary *dict = (NSDictionary *)notification.object;
    if (!dict) {
        return;
    }
    
    [self pushPayload:dict[@"payload"] withToken:dict[@"token"] andSandbox:[dict[@"sandbox"] boolValue]];
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
