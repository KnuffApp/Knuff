//
//  SBNetServiceSearcher.h
//  APNS Pusher
//
//  Created by Simon Blommegård on 2012-10-31.
//  Copyright (c) 2012 Simon Blommegård. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBNetServiceSearcher : NSObject
@property (nonatomic, getter=isSearching, assign) BOOL searching;
@property (nonatomic, readonly, strong) NSMutableArray *availableNetServices;
@end
