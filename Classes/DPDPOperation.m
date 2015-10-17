//
//  DPDPOperation.m
//  DPDplus
//
//  Created by hewig on 5/19/15.
//  Copyright (c) 2015 fourplex. All rights reserved.
//

#import "DPDPOperation.h"
#import "DPDPRecord.h"

static NSString *kDPDPHost = @"119.29.29.29";

@interface DPDPOperation ()

@property (nonatomic, strong, readwrite) DPDPRecord *resultRecord;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation DPDPOperation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestTimeout = 10;
    }
    return self;
}

- (void)main
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/d?dn=%@&ttl=1", kDPDPHost, self.domain]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.requestTimeout];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        self.error = error;
    } else {
        if (data.length == 0) {
            NSLog(@"empty response, DNSPod resolve failed?");
            return;
        }
        
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        DPDPRecord *record = [[DPDPRecord alloc] initWithResponseString:dataString];
        record.host = self.domain;
        self.resultRecord = record;
    }
}

@end
