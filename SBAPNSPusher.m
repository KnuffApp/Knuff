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
@property (nonatomic, strong) NSData *token;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation SBAPNSPusher

+ (void)start {
  id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
  
  // application:didRegisterForRemoteNotificationsWithDeviceToken:
  SEL newSEL = NSSelectorFromString(@"sb_application:didRegisterForRemoteNotificationsWithDeviceToken:");
  IMP newIMP = imp_implementationWithBlock(^(id _self, UIApplication *application, NSData *token) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_self performSelector:newSEL withObject:application withObject:token];
#pragma clang diagnostic pop
    
    dispatch_async([SBAPNSPusher _sniffer].queue, ^{
      [[SBAPNSPusher _sniffer] setToken:token];
      [[SBAPNSPusher _sniffer] _republish];
    });
  });
  
  SEL origSEL = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
  Method origMethod = class_getInstanceMethod([appDelegate class], origSEL);
  
  class_addMethod([appDelegate class], newSEL, newIMP, method_getTypeEncoding(origMethod));
  sb_swizzle([appDelegate class], origSEL, newSEL);
  
  [[NSNotificationCenter defaultCenter] addObserver:[SBAPNSPusher _sniffer]
                                           selector:@selector(_applicationDidBecomeActiveNotification:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

#pragma mark - Private

+ (SBAPNSPusher *)_sniffer {
  static dispatch_once_t onceToken;
  static SBAPNSPusher *sniffer;
  
  dispatch_once(&onceToken, ^{
    sniffer = [SBAPNSPusher new];
  });
  
  return sniffer;
}

- (void)_republish {
  [self.netService stop];
  [self.netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:@{@"token":self.token}]];
  [self.netService publish];
}

- (void)_applicationDidBecomeActiveNotification:(NSNotification *)notification {
  dispatch_async([SBAPNSPusher _sniffer].queue, ^{
    if ([SBAPNSPusher _sniffer].token)
      [[SBAPNSPusher _sniffer] _republish];
  });
}

#pragma mark - Properties

- (NSNetService *)netService {
  if (!_netService) {
    _netService = [[NSNetService alloc] initWithDomain:@"" type:@"_apnspusher._tcp" name:[UIDevice currentDevice].name port:1337];
    [_netService setDelegate:self];
  }
  return _netService;
}

- (dispatch_queue_t)queue {
  if (!_queue) {
    _queue = dispatch_queue_create("se.simonb.SBAPNSPusherQueue", NULL);
    dispatch_set_target_queue(_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
  }
  return _queue;
}

@end