//
//  PBAppDelegate.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-12.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SBAppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, readonly, assign) NSString *identityName;

@property (nonatomic, strong, readonly) NSString *alertString;
@property (nonatomic, strong, readonly) NSString *soundString;
@property (nonatomic, strong, readonly) NSString *badgeString;

@property (nonatomic, strong) IBOutlet NSTextField *tokenTextField;

@property (nonatomic, strong) IBOutlet NSView *containerView;

- (IBAction)chooseIdentity:(id)sender;
- (IBAction)chooseNetServiceDevice:(id)sender;
- (IBAction)push:(id)sender;
- (IBAction)exportIdentity:(id)sender;
@end
