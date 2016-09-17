//
//  APNSIdentity.h
//  Knuff
//
//  Created by Joel Ekström on 2016-09-17.
//  Copyright © 2016 Bowtie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APNSSecIdentityType.h"
#import <Cocoa/Cocoa.h>

extern NSString * const APNSDefaultIdentityDidChangeNotification;

@interface APNSIdentity : NSObject

- (instancetype)initWithSecIdentityRef:(SecIdentityRef)ref;

@property (nonatomic, readonly) APNSSecIdentityType type;
@property (nonatomic, readonly) NSArray<NSString *> *topics;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSURLCredential *credecential;

- (void)exportWithPanelWindow:(NSWindow *)window;

+ (instancetype)defaultIdentity;
+ (void)setDefaultIdentity:(APNSIdentity *)identity;

@end
