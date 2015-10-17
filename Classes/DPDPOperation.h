//
//  DPDPOperation.h
//  DPDplus
//
//  Created by hewig on 5/19/15.
//  Copyright (c) 2015 fourplex. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DPDPRecord;
@interface DPDPOperation : NSOperation

@property (nonatomic, strong) NSString *domain;
@property (nonatomic, assign) NSTimeInterval requestTimeout;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) DPDPRecord *resultRecord;

@end
