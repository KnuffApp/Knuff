//
//  SettingsViewController.h
//  Knuff
//
//  Created by Joel Ekström on 2016-09-16.
//  Copyright © 2016 Bowtie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SettingsViewController : NSViewController

@property (nonatomic, weak) IBOutlet NSTextField *tokenTextField;
@property (nonatomic, weak) IBOutlet NSTextField *identityTextField;

@end
