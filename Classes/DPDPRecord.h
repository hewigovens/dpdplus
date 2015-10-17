//
//  DPDPRecord.h
//  DPDplus
//
//  Created by hewig on 5/21/15.
//  Copyright (c) 2015 fourplex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DPDPRecord : NSObject

@property (nonatomic, copy) NSString *host;
@property (nonatomic, copy) NSArray *ips;
@property (nonatomic, assign) NSTimeInterval ttl;
@property (nonatomic, assign) NSTimeInterval timestamp;

/*
 * format:
 * ip;ip;ip,ttl
 */
- (instancetype)initWithResponseString:(NSString *)responseString;

@end
