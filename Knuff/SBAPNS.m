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
@property (nonatomic, strong) NSData *dataToSendAfterConnect;
@property (nonatomic) BOOL connectDueToIdentityChange;
@end

@implementation SBAPNS

- (id)init {
	if (self = [super init]) {
		_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	}
	return self;
}

- (void)dealloc {
  if (_identity != NULL) {
    CFRelease(_identity);
    _identity = NULL;
  }
}

#pragma mark - Properties

- (void)setIdentity:(SecIdentityRef)identity {
  BOOL disconnected = NO;
  
	if (_identity != identity) {
    if (_identity != NULL) {
      if (self.socket.isConnected) {
        disconnected = YES;
        [self.socket disconnect];
      }
    
      CFRelease(_identity);
    }
    if (identity != NULL) {
      _identity = (SecIdentityRef)CFRetain(identity);
      
      if (disconnected) {
        // will cause connect in -socketDidDisconnect:withError:
        self.connectDueToIdentityChange = YES;
      } else {
        [self connectSocket];
      }
    } else {
      _identity = NULL;
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

- (void)pushPayload:(NSDictionary *)payload toToken:(NSString *)token withPriority:(uint8_t)priority {
  NSData *data = [APNSFrameBuilder dataFromToken:token
                                        playload:payload
                                      identifier:0
                                  expirationDate:0
                                        priority:priority];
  
  
  if (data && self.socket.isConnected && self.socket.isSecure) {
    [self.socket writeData:data withTimeout:-1 tag:APNSSockTagWrite];
  } else if (data && self.identity) {
    self.dataToSendAfterConnect = data;
    [self connectSocket];
  } else {
    // error
  }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  if (self.connectDueToIdentityChange && self.identity != NULL) {
    self.connectDueToIdentityChange = NO;
    [self connectSocket];
  }
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
  // Start reading error messages
  [sock readDataToLength:6 withTimeout:-1 tag:APNSSockTagRead];
  
  if (self.dataToSendAfterConnect) {
    [self.socket writeData:self.dataToSendAfterConnect withTimeout:-1 tag:APNSSockTagWrite];
    self.dataToSendAfterConnect = nil;
  }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if (tag == APNSSockTagRead && _APNSErrorBlock) {
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
		
		_APNSErrorBlock(status, desc, identifier);

    [sock disconnect];
	}
}

@end
