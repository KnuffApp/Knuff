//
//  APNS.m
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import "SBAPNS.h"
#import <Security/Security.h>
#import "APNSSecIdentityType.h"

@interface SBAPNS () <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation SBAPNS

- (id)init {
	if (self = [super init]) {
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:conf
                                                 delegate:self
                                            delegateQueue:[NSOperationQueue mainQueue]];
	}
	return self;
}

#pragma mark - Properties

#pragma mark -



#pragma mark - Public

- (void)pushPayload:(nonnull NSDictionary *)payload
            toToken:(nonnull NSString *)token
          withTopic:(nullable NSString *)topic
           priority:(NSUInteger)priority
          inSandbox:(BOOL)sandbox {
  
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api%@.push.apple.com/3/device/%@", sandbox?@".development":@"", token]]];
  request.HTTPMethod = @"POST";
  
  request.HTTPBody = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
  
  if (topic) {
    [request addValue:topic forHTTPHeaderField:@"apns-topic"];
  }
  
  [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)priority] forHTTPHeaderField:@"apns-priority"];
  
  // apns-expiration
  // apns-id
  
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
  [task resume];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didReceiveChallenge:(nonnull NSURLAuthenticationChallenge *)challenge completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
  SecCertificateRef certificate;
  
  SecIdentityCopyCertificate(self.identity, &certificate);
  
  NSURLCredential *cred = [[NSURLCredential alloc] initWithIdentity:self.identity
                                                       certificates:@[(__bridge_transfer id)certificate]
                                                        persistence:NSURLCredentialPersistenceNone];
  
  completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
}

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
  
}

@end
