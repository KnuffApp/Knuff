//
//  SettingsViewController.m
//  Knuff
//
//  Created by Joel Ekström on 2016-09-16.
//  Copyright © 2016 Bowtie. All rights reserved.
//

#import "SettingsViewController.h"
#import "APNSIdentityChooser.h"
#import "Constants.h"

@interface SettingsViewController () <NSTextFieldDelegate>

@end

@implementation SettingsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self updateIdentityName];
  [self.tokenTextField setPlaceholderString:APNSPlaceholderToken];
  NSString *defaultToken = [[NSUserDefaults standardUserDefaults] stringForKey:APNSDefaultTokenKey];
  if (defaultToken) {
    [self.tokenTextField setStringValue:defaultToken];
  }
}

- (void)controlTextDidChange:(NSNotification *)notification {
  NSString *token = self.tokenTextField.stringValue;
  [[NSUserDefaults standardUserDefaults] setObject:token forKey:APNSDefaultTokenKey];
  [[NSNotificationCenter defaultCenter] postNotificationName:APNSDefaultTokenDidChangeNotification object:nil userInfo:@{APNSDefaultTokenKey: token}];
}

- (IBAction)chooseIdentity:(id)sender {
  APNSIdentityChooser *chooser = [APNSIdentityChooser new];
  [chooser displayWithWindow:self.view.window completion:^(APNSIdentity *selectedIdentity) {
    [APNSIdentity setDefaultIdentity:selectedIdentity];
    [self updateIdentityName];
  }];
}

- (void)updateIdentityName
{
  if ([APNSIdentity defaultIdentity]) {
    [self.identityTextField setStringValue:[APNSIdentity defaultIdentity].displayName];
  } else {
    [self.identityTextField setStringValue:@"Choose default identity"];
  }
}

@end
