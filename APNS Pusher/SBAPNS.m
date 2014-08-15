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
#import "SBIdentityTypeDetection.h"

typedef enum {
	APNSSockTagWrite,
	APNSSockTagRead
} APNSSockTag;

@interface SBAPNS () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *socket;

@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSDictionary *payload;
@end

@implementation SBAPNS

- (id)init {
	if (self = [super init]) {
		_socket = [[GCDAsyncSocket alloc] init];
		[_socket setDelegate:self delegateQueue:dispatch_get_current_queue()];
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
    if (_identity != NULL)
      CFRelease(_identity);
    if (identity != NULL)
      _identity = (SecIdentityRef)CFRetain(identity);
  }
}

#pragma mark - Public

- (void)pushPayload:(NSDictionary *)payload withToken:(NSString *)token {
  [self setPayload:payload];
  [self setToken:token];
  
  SBIdentityType type = SBSecIdentityGetType(_identity);
  BOOL isSandbox = (type == SBIdentityTypeDevelopment);
  
  NSString *host = isSandbox?@"gateway.sandbox.push.apple.com":@"gateway.push.apple.com";
  
  NSError *error;
  [_socket connectToHost:host onPort:2195 error:&error];
  
  if(error) {
    NSLog(@"Failed to connect: %@", error);
    return;
  }
  
  [_socket startTLS:@{
                      (NSString *)kCFStreamSSLCertificates: @[(__bridge id)_identity],
                      (NSString *)kCFStreamSSLPeerName: host
                      }];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socketDidSecure:(GCDAsyncSocket *)sock {  
	NSData *payloadData = self.payload?[NSJSONSerialization dataWithJSONObject:self.payload options:0 error:nil]:nil;
	
	// https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW1
  
  // frame
  NSMutableData *frame = [NSMutableData data];
  
  uint8_t itemId = 0;
  uint16_t itemLength = 0;

  // item 1, token
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // token length, network order
  itemLength = htons(32);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // token
  NSMutableData *token = [NSMutableData data];
  unsigned value;
  NSScanner *scanner = [NSScanner scannerWithString:_token];
  while(![scanner isAtEnd]) {
    [scanner scanHexInt:&value];
    value = htonl(value);
    [token appendBytes:&value length:sizeof(value)];
  }
  
  [frame appendData:token];
  
  // item 2, payload
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // payload length, network order
  itemLength = htons([payloadData length]);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // payload
  [frame appendData:payloadData];
  
  // item 3, notification identifier
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // notification identifier length, network order
  itemLength = htons(4);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // notification identifier
  uint32_t notificationIdentifier = 0;
  [frame appendBytes:&notificationIdentifier length:sizeof(uint32_t)];
  
  // item 4, expiration date
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // expiration date lenght, network order
  itemLength = htons(4);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // expiration date
  uint32_t expirationDate = htonl(0);
  [frame appendBytes:&expirationDate length:sizeof(uint32_t)];
  
  // item 5, priority
  itemId++;
  [frame appendBytes:&itemId length:sizeof(uint8_t)];
  
  // priority length, network order
  itemLength = htons(1);
  [frame appendBytes:&itemLength length:sizeof(uint16_t)];
  
  // priority
  uint8_t priority = 10; // 5 if only "content-available"
  [frame appendBytes:&priority length:sizeof(uint8_t)];
  
  // data
  NSMutableData *data = [NSMutableData data];
  
  // command
  uint8_t command = 2;
  [data appendBytes:&command length:sizeof(uint8_t)];
  
	// frame length, network order
	uint32_t frameLength = htonl([frame length]);
	[data appendBytes:&frameLength length:sizeof(uint32_t)];

  // frame
  [data appendData:frame];
	
	[sock writeData:data withTimeout:2. tag:APNSSockTagWrite];

  // Always kill after 4 sec
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4. * NSEC_PER_SEC), dispatch_get_current_queue(), ^(void){
		if ([sock isConnected])
			[sock disconnect];
	});
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	if (tag == APNSSockTagWrite)
		[sock readDataToLength:6 withTimeout:2. tag:APNSSockTagRead];
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
