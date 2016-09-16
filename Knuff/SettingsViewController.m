//
//  SettingsViewController.m
//  Knuff
//
//  Created by Joel Ekström on 2016-09-16.
//  Copyright © 2016 Bowtie. All rights reserved.
//

#import "SettingsViewController.h"
#import "Constants.h"

@interface SettingsViewController () <NSTextFieldDelegate>

@end

@implementation SettingsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
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

@end
