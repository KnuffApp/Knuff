//
//  APNSKnuffService.m
//  APNS Pusher
//
//  Created by Simon Blommegard on 24/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNSKnuffService.h"

@interface APNSKnuffService ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation APNSKnuffService

- (instancetype)init {
  if (self = [super init]) {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
  }
  
  return self;
}

#pragma mark - APNSKnuffService

- (void)pushPayload:(NSDictionary *)payload
            toToken:(NSString *)token
       withPriority:(NSUInteger)priority
             expiry:(NSUInteger)expiry {
  
  NSDictionary *parameters = @{
                               @"payload":payload,
                               @"token":token,
                               @"priority":@(priority),
                               @"expiry":@(expiry)
                               };

  NSURL *URL = [NSURL URLWithString:@"https://knuff.herokuapp.com"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  
  [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  
  [request setHTTPMethod:@"POST"];
  
  NSError *error;
  NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
  
  if (!error) {
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      
    }];
    
    [task resume];
  }
}

@end
