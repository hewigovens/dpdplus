//
//  DPDPRecord.m
//  DPDplus
//
//  Created by hewig on 5/21/15.
//  Copyright (c) 2015 fourplex. All rights reserved.
//

#import "DPDPRecord.h"
#import "DPDPlus.h"

@implementation DPDPRecord

- (instancetype)initWithResponseString:(NSString *)responseString
{
    self = [super init];
    if (self) {
        NSArray *array = [responseString componentsSeparatedByString:@","];
        if (array.count == 2) {
            NSString *ttl = [array lastObject];
            _ttl = ttl.doubleValue;
            _timestamp = [DPDPlus now];
            
            NSString *ipStrings = [array firstObject];
            _ips = [ipStrings componentsSeparatedByString:@";"];
        }
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString new];
    [desc appendFormat:@"%@\n",NSStringFromClass([self class])];
    [desc appendFormat:@"\t host: %@\n", self.host];
    [desc appendFormat:@"\t ips: %@\n", self.ips];
    [desc appendFormat:@"\t timestamp: %f\n", self.timestamp];
    [desc appendFormat:@"\t ttl: %f\n", self.ttl];
    return [NSString stringWithString:desc];
}

@end
