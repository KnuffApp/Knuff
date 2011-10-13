//
//  PBAppDelegate.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-12.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBAppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, readonly, assign) NSString *identityName;
@property (nonatomic, assign, getter = isSandbox) BOOL sandbox;

@property (nonatomic, strong) IBOutlet NSTextField *tokenTextField;
@property (nonatomic, strong) IBOutlet NSTextField *alertTextField;
@property (nonatomic, strong) IBOutlet NSTextField *soundTextField;
@property (nonatomic, strong) IBOutlet NSTextField *badgeTextField;

- (IBAction)chooseIdentity:(id)sender;
- (IBAction)push:(id)sender;
@end
