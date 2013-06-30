//
//  SBViewController.m
//  iOS APNS Pusher
//
//  Created by Prince on 13/6/30.
//  Copyright (c) 2013年 Doubleint. All rights reserved.
//

#import "SBViewController.h"

NSString * const kPBAppDelegateDefaultPayload = @"{\n\t\"aps\":{\n\t\t\"alert\":\"Test\",\n\t\t\"sound\":\"default\",\n\t\t\"badge\":0\n\t}\n}";

@interface SBViewController () {
    __weak IBOutlet UISwitch *sandboxSwitch;
}

@end

@implementation SBViewController

- (NSDictionary *)payload:(NSString *)payloadStr {
    NSData *data = [payloadStr dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data) {
        NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if (payload && [payload isKindOfClass:[NSDictionary class]])
            return payload;
    }
    
    return nil;
}

#pragma - public

- (IBAction)pushPayload:(UIButton *)sender {
    
    NSDictionary *payload = [self payload:kPBAppDelegateDefaultPayload];

    NSString *token = @"3d28a4ae 0a8fb602 1d50edfe ead628a1 5159584c b7efcdf5 ece058c2 23d518da";
    BOOL sandbox = [sandboxSwitch isOn];
    
    NSDictionary *dict = @{@"token": token, @"payload":payload, @"sandbox": @(sandbox) };
    [[NSNotificationCenter defaultCenter] postNotificationName:kPushNotificationKey object:dict];
}

#pragma - mark view life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
