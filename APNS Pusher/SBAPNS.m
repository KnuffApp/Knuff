//
//  APNS.m
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import "SBAPNS.h"
#import <Security/Security.h>
#import "GCDAsyncSocket.h"
#import "APNSSecIdentityType.h"
#import "APNSFrameBuilder.h"

typedef enum {
	APNSSockTagWrite,
	APNSSockTagRead
} APNSSockTag;

@interface SBAPNS () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *socket;
@end

@implementation SBAPNS

- (id)init {
	if (self = [super init]) {
		_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	}
	return self;
}

- (void)dealloc {
  if (_identity != NULL)
    CFRelease(_identity);
}

#pragma mark - Properties

- (void)setIdentity:(SecIdentityRef)identity {
	if (_identity != identity) {
    if (_identity != NULL) {
      if (self.socket.isConnected) {
        [self.socket disconnect];
      }
    
      CFRelease(_identity);
    }
    if (identity != NULL) {
      _identity = (SecIdentityRef)CFRetain(identity);
      [self connectSocket];
    }
  }
}

#pragma mark -

- (void)connectSocket {
  APNSSecIdentityType type = APNSSecIdentityGetType(_identity);
  
  NSString *host = (type == APNSSecIdentityTypeDevelopment)?
  @"gateway.sandbox.push.apple.com":
  @"gateway.push.apple.com";
  
  NSError *error;
  [self.socket connectToHost:host onPort:2195 error:&error];
  
  if(error) {
    NSLog(@"Failed to connect: %@", error);
    return;
  }
  
  [self.socket startTLS:@{
                          (NSString *)kCFStreamSSLCertificates: @[(__bridge id)_identity],
                          (NSString *)kCFStreamSSLPeerName: host
                          }];
}

#pragma mark - Public

- (BOOL)pushPayload:(NSDictionary *)payload withToken:(NSString *)token {
  if(!self.socket.isSecure) {
    return NO;
  }
  
  NSError *error;
  [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];
  
  if (error != nil) {
    return NO;
  }
  
  if (!token) {
    return NO;
  }
  
  uint8_t priority = 10;
  
  NSArray *APSKeys = [[payload objectForKey:@"aps"] allKeys];
  if (APSKeys.count == 1 && [APSKeys.lastObject isEqualTo:@"content-available"]) {
    priority = 5;
  }
  
  NSData *data = [APNSFrameBuilder dataFromToken:token
                                        playload:payload
                                      identifier:0
                                  expirationDate:0
                                        priority:priority];
  
  [self.socket writeData:data withTimeout:2. tag:APNSSockTagWrite];
  
  return YES;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
  if (tag == APNSSockTagWrite) {
    [sock readDataToLength:6 withTimeout:1000 tag:APNSSockTagRead];
  }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  if (self.identity != NULL) {
    [self connectSocket];
  }
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
  // Start reading error messages

}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if (tag == APNSSockTagRead && _errorBlock) {
		uint8_t status;
		uint32_t identifier;
		
		[data getBytes:&status range:NSMakeRange(1, 1)];
		[data getBytes:&identifier range:NSMakeRange(2, 4)];
		
		NSString *desc;
		
    // http://developer.apple.com/library/mac/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW1
		switch (status) {
			case 0:
				desc = @"No errors encountered";
				break;
			case 1:
				desc = @"Processing error";
				break;
			case 2:
				desc = @"Missing device token";
				break;
			case 3:
				desc = @"Missing topic";
				break;
			case 4:
				desc = @"Missing payload";
				break;
			case 5:
				desc = @"Invalid token size";
				break;
			case 6:
				desc = @"Invalid topic size";
				break;
			case 7:
				desc = @"Invalid payload size";
				break;
			case 8:
				desc = @"Invalid token";
				break;
      case 10:
        desc = @"Shutdown";
        break;
			default:
				desc = @"None (unknown)";
				break;
		}
		
		_errorBlock(status, desc, identifier);

    [sock disconnect];
	}
}

@end
