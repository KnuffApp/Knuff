//
//  APNSItem.h
//  APNS Pusher
//
//  Created by Simon Blommegard on 14/03/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "MTLModel.h"

@interface APNSItem : MTLModel
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *payload;
@end
