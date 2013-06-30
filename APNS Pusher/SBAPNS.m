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

- (BOOL)isReady {
  return self.socket.isDisconnected;
}

#pragma mark - Public

- (void)pushPayload:(NSDictionary *)payload withToken:(NSString *)token {
  [self setPayload:payload];
  [self setToken:token];
  
  NSString *host = _sandbox? @"gateway.sandbox.push.apple.com":@"gateway.push.apple.com";
  
  NSError *error;
  [_socket connectToHost:host onPort:2195 error:&error];
  
  if(error) {
    NSLog(@"Failed to connect: %@", error);
    return;
  }
  
  NSMutableDictionary *options = [NSMutableDictionary dictionary];
  [options setObject:@[(__bridge id)_identity] forKey:(NSString *)kCFStreamSSLCertificates];
  [options setObject:host forKey:(NSString *)kCFStreamSSLPeerName];
  
  [_socket startTLS:options];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socketDidSecure:(GCDAsyncSocket *)sock {  
	NSData *payloadData = self.payload?[NSJSONSerialization dataWithJSONObject:self.payload options:0 error:nil]:nil;
	
	// Format: |COMMAND|ID|EXPIRY|TOKENLEN|TOKEN|PAYLOADLEN|PAYLOAD| */
	NSMutableData *data = [NSMutableData data];
	
	// command
	uint8_t command = 1; // extended
	[data appendBytes:&command length:sizeof(uint8_t)];
	
	// identifier
	uint32_t identifier = 0; // leave 0 for now
	[data appendBytes:&identifier length:sizeof(uint32_t)];
	
	// expiry, network order
	uint32_t expiry = htonl(time(NULL)+86400); // 1 day
	[data appendBytes:&expiry length:sizeof(uint32_t)];
	
	// token length, network order
	uint16_t tokenLength = htons(32);
	[data appendBytes:&tokenLength length:sizeof(uint16_t)];
	
	// token
	NSMutableData *token = [NSMutableData data];
	unsigned value;
	NSScanner *scanner = [NSScanner scannerWithString:_token];
	while(![scanner isAtEnd]) {
		[scanner scanHexInt:&value];
		value = htonl(value);
		[token appendBytes:&value length:sizeof(value)];
	}
	
	[data appendData:token];
	
	// payload length, network order
	uint16_t payloadLength = htons([payloadData length]);
	[data appendBytes:&payloadLength length:sizeof(uint16_t)];
	
	// payload
	[data appendData:payloadData];
	
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
