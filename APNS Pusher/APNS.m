//
//  APNS.m
//  APNS Pusher
//
//  Created by Simon Blommegård on 2011-10-13.
//  Copyright (c) 2011 Simon Blommegård. All rights reserved.
//

#import "APNS.h"
#import <Security/Security.h>
#import "GCDAsyncSocket.h"

typedef enum {
	APNSSockTagWrite,
	APNSSockTagRead
} APNSSockTag;

#define DEVICE_BINARY_SIZE 32
#define MAXPAYLOAD_SIZE 256

@interface APNS () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *socket;

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *alert;
@property (nonatomic, strong) NSString *sound;
@property (nonatomic, assign) NSInteger badge;
@end

@implementation APNS

@synthesize identity = _identity;
@synthesize sandbox = _sandbox;
@synthesize errorBlock = _errorBlock;

@synthesize socket = _socket;
@synthesize token = _token;
@synthesize alert = _alert;
@synthesize sound = _sound;
@synthesize badge = _badge;

- (id)init {
	if ((self = [super init])) {
		_socket = [[GCDAsyncSocket alloc] init];
		[_socket setDelegate:self delegateQueue:dispatch_get_current_queue()];
	}
	return self;
}

- (void)dealloc {
	if (_identity != NULL)
		CFRelease(_identity);
}

+ (APNS *)sharedAPNS {
	__strong static id APNS = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
    APNS = [self new];
	});
	
	return APNS;
}

#pragma mark - Properties

- (void)setIdentity:(SecIdentityRef)identity {
	if (_identity != NULL)
		CFRelease(_identity), _identity = NULL;

	_identity = identity;
}

- (void)pushWithToken:(NSString *)token alert:(NSString *)alert sound:(NSString *)sound badge:(NSInteger)badge {
	[self setToken:token];
	[self setAlert:alert];
	[self setSound:sound];
	[self setBadge:badge];
	
	NSString *host = _sandbox? @"gateway.sandbox.push.apple.com":@"gateway.push.apple.com";
	
	NSError *error;
	[_socket connectToHost:host onPort:2195 error:&error];
	
	NSLog(@"%@", host);
	
	if(error) {
		NSLog(@"Failed to connect: %@", error);
		return;
	}
	
	NSMutableDictionary *options = [NSMutableDictionary dictionary];
	[options setObject:[NSArray arrayWithObject:(__bridge id)_identity] forKey:(NSString *)kCFStreamSSLCertificates];
	[options setObject:host forKey:(NSString *)kCFStreamSSLPeerName];
	
	[_socket startTLS:options];
}


- (void)socketDidSecure:(GCDAsyncSocket *)sock {
//	NSString *payload = @"{\"aps\":{\"alert\":\"Lol\",\"badge\":5,\"sound\":\"default\"}}";
	NSDictionary *payload = [NSDictionary dictionaryWithObject:
													 [NSDictionary dictionaryWithObjectsAndKeys:
														_alert, @"alert",
														_sound, @"sound",
														[NSNumber numberWithInteger:_badge], @"badge", nil] forKey:@"aps"];
	
	NSData *payloadData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
	
	// Format: |COMMAND|ID|EXPIRY|TOKENLEN|TOKEN|PAYLOADLEN|PAYLOAD| */
	NSMutableData *data = [NSMutableData data];
	
	// command
	uint8_t command = 1;
	[data appendBytes:&command length:sizeof(uint8_t)];
	
	// identifier
	uint32_t identifier = 1234;
	[data appendBytes:&identifier length:sizeof(uint32_t)];
	
	// expiry, network order
	uint32_t expiry = htonl(time(NULL)+86400); // 1 day
	[data appendBytes:&expiry length:sizeof(uint32_t)];
	
	// token length, network order
	uint16_t tokenLength = htons(DEVICE_BINARY_SIZE);
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
	
	[sock writeData:data withTimeout:5. tag:APNSSockTagWrite];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6. * NSEC_PER_SEC), dispatch_get_current_queue(), ^(void){
		if ([sock isConnected])
			[sock disconnect];
	});
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	if (tag == APNSSockTagWrite)
		[sock readDataToLength:6 withTimeout:5. tag:APNSSockTagRead];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if (tag == APNSSockTagRead && _errorBlock) {
		uint8_t status;
		uint32_t identifier;
		
		[data getBytes:&status range:NSMakeRange(1, 1)];
		[data getBytes:&identifier range:NSMakeRange(2, 4)];
		
		NSString *desc;
		
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
			default:
				desc = @"None (unknown)";
				break;
		}
		
		_errorBlock(status, desc, identifier);

		[sock disconnect];
	}
}

@end
