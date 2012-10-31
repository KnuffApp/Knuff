//
//  SBAPNSPusher.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2012-10-31.
//  Copyright (c) 2012 Simon Blommegård. All rights reserved.
//

#import "SBAPNSPusher.h"
#import <objc/runtime.h>

void sb_swizzle(Class class, SEL orig, SEL new) {
  Method origMethod = class_getInstanceMethod(class, orig);
  Method newMethod = class_getInstanceMethod(class, new);
  if(class_addMethod(class, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
    class_replaceMethod(class, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
  else
    method_exchangeImplementations(origMethod, newMethod);
}

@interface SBAPNSPusher () <NSNetServiceDelegate>
@property (nonatomic, strong) NSNetService *netService;

+ (SBAPNSPusher *)_sniffer;
- (void)_publishWithToken:(NSData *)token;
@end

@implementation SBAPNSPusher

+ (void)start {
  SEL newSEL = NSSelectorFromString(@"sb_application:didRegisterForRemoteNotificationsWithDeviceToken:");
  IMP newIMP = imp_implementationWithBlock(^(id _self, UIApplication *application, NSData *token) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_self performSelector:newSEL withObject:application withObject:token];
#pragma clang diagnostic pop
    [[SBAPNSPusher _sniffer] _publishWithToken:token];
  });
  
  id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
  
  SEL origSEL = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  Method origMethod = class_getInstanceMethod([appDelegate class], origSEL);
  
  class_addMethod([appDelegate class], newSEL, newIMP, method_getTypeEncoding(origMethod));
  sb_swizzle([appDelegate class], origSEL, newSEL);
}

#pragma mark -

+ (SBAPNSPusher *)_sniffer {
  static dispatch_once_t onceToken;
  static SBAPNSPusher *spoofer;
  
  dispatch_once(&onceToken, ^{
    spoofer = [SBAPNSPusher new];
  });
  
  return spoofer;
}

- (void)_publishWithToken:(NSData *)token {
  [self.netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:@{@"token":token}]];
  [self.netService publish];
}

#pragma mark - Properties

- (NSNetService *)netService {
  if (!_netService) {
    _netService = [[NSNetService alloc] initWithDomain:@"" type:@"_apnspusher._tcp" name:[UIDevice currentDevice].name port:1337];
    [_netService setDelegate:self];
  }
  return _netService;
}

@end