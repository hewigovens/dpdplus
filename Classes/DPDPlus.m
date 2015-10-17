//
//  DPDPlus.m
//  DPDplus
//
//  Created by hewig on 5/19/15.
//  Copyright (c) 2015 fourplex. All rights reserved.
//

#import "DPDPlus.h"
#import "DPDPOperation.h"
#import "DPDPRecord.h"

#import <dispatch/dispatch.h>
#import <mach/mach_time.h>

#define DPDPLUS [DPDPlus sharedInstance]

#pragma mark - DPDPlus

@interface DPDPlus()

@property (strong) NSMutableDictionary *cache;
@property (strong) NSMutableDictionary *reverseCache;
@property (strong) NSMutableSet *domains;
@property (strong) NSMutableDictionary *timers;

@property (nonatomic, strong) NSOperationQueue *networkQueue;
@property (nonatomic, assign) NSTimeInterval requestTimeout;

@end

@implementation DPDPlus

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cache = [NSMutableDictionary new];
        _reverseCache = [NSMutableDictionary new];

        _domains = [NSMutableSet new];
        _timers = [NSMutableDictionary new];
        
        _networkQueue = [NSOperationQueue new];
        _networkQueue.name = @"in.fourplex.DPDPlus.network";
        
        _requestTimeout = 15;
    }
    return self;
}

- (void)registerDomains:(NSArray *)domains
{
    for (NSString *domain in domains) {
        [self.domains addObject:domain];
        [self resolveDomain:domain];
    }
}

- (void)resolveDomain:(NSString *)domain
{
    DPDPOperation *operation = [DPDPOperation new];
    operation.domain = domain;
    
    __weak DPDPOperation *weakOperation = operation;
    __weak typeof(self) weakSelf = self;
    [operation setCompletionBlock:^{
        DPDPOperation *strongOperation = weakOperation;
        if (strongOperation.error) {
            NSLog(@"%@", strongOperation.error);
            NSInteger code = strongOperation.error.code;
            if (code == NSURLErrorUnknown ||
                code == NSURLErrorTimedOut ||
                code == NSURLErrorCannotConnectToHost ||
                code == NSURLErrorNetworkConnectionLost) {
                
                DPDPRecord *record = [DPDPRecord new];
                record.host = domain;
                record.ttl = weakSelf.requestTimeout;
                record.timestamp = [DPDPlus now];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf updateTTLTimerForRecord:record];
                });
            }
        } else {
            NSLog(@"%@", strongOperation.resultRecord);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateTTLTimerForRecord:strongOperation.resultRecord];
            });
        }
    }];
    
    NSLog(@"==> start resolving %@", domain);
    [self.networkQueue addOperation:operation];
}

- (void)updateTTLTimerForRecord:(DPDPRecord *)record
{
    if (record == nil || record.host == nil) {
        return;
    }
    
    NSString *domain = record.host;
    if (record.ips.count > 0) {
        for (NSString *ip in record.ips) {
            self.reverseCache[ip] = record.host;
        }
        self.cache[record.host] = record;
    }
    
    NSDictionary *timerInfo = self.timers[domain];
    NSTimer *domainTimer = timerInfo[@"TimerValue"];
    
    if (domainTimer) {
        [domainTimer invalidate];
        domainTimer = nil;
    }
    
    domainTimer = [NSTimer scheduledTimerWithTimeInterval:record.ttl * 0.9
                                                   target:self
                                                 selector:@selector(timerFired:)
                                                 userInfo:@{@"Domain":domain}
                                                  repeats:NO];
    self.timers[domain] = @{@"TimerValue" : domainTimer};
}

- (void)timerFired:(NSTimer *)timer
{
    NSDictionary *userInfo = timer.userInfo;
    if (userInfo) {
        NSString *domain = userInfo[@"Domain"];
        if (domain) {
            [self resolveDomain:domain];
        }
    }
}

- (void)updateCache
{
    NSArray *domains = [self.domains allObjects];

    [self cancelAllTimers];
    [self.domains removeAllObjects];
    [self.reverseCache removeAllObjects];
    [self.cache removeAllObjects];
    
    [self registerDomains:domains];
}

- (void)cancelTimerWithName:(NSString *)name
{
    
    NSTimer *timer = self.timers[name][@"TimerValue"];
    if (timer) {
        [timer invalidate];
        [self.timers removeObjectForKey:name];
    }
}

- (void)cancelAllTimers
{
    for (NSString *name in self.timers.allKeys) {
        [self cancelTimerWithName:name];
    }
}

#pragma mark Class Methods

+(instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static DPDPlus *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [DPDPlus new];
    });
    return instance;
}

+ (NSTimeInterval)now
{
    static mach_timebase_info_data_t info;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{ mach_timebase_info(&info); });
    
    NSTimeInterval t = mach_absolute_time();
    t *= info.numer;
    t /= info.denom;
    return t / NSEC_PER_SEC;
}

+ (void)setRequestTimeout:(NSTimeInterval)timeout
{
    DPDPLUS.requestTimeout = timeout;
}

+ (void)registerDomains:(NSArray *)domains
{
    [DPDPLUS registerDomains:domains];
}

+ (void)updateCache
{
    [DPDPLUS updateCache];
}

+ (NSArray *)ipAddressesForDomain:(NSString *)domain
{
    if (domain == nil || domain.length == 0) {
        return @[];
    }
    DPDPRecord *record = [DPDPLUS.cache objectForKey:domain];
    return record.ips;
}

+ (void)applyHTTPDNSForRequest:(NSMutableURLRequest *)request
{
    if (!request) {
        return;
    }
    
    NSURL *url = request.URL;
    NSString *host = url.host;
    if (DPDPLUS.cache[host]) {
        DPDPRecord *record = DPDPLUS.cache[host];
        if ([record.ips firstObject]) {
            NSString *urlString = url.absoluteString;
            urlString = [urlString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@://%@", url.scheme, url.host]
                                                             withString:[NSString stringWithFormat:@"%@://%@", url.scheme, [record.ips firstObject]]];
            request.URL = [NSURL URLWithString:urlString];
            [request setValue:host forHTTPHeaderField:@"Host"];
        }
    }
}

+ (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
    NSMutableArray *policies = [NSMutableArray array];
    NSString *actualDomain = DPDPLUS.reverseCache[domain];
    
    if (actualDomain) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)actualDomain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    }
    
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);

    BOOL isValid = NO;
    SecTrustResultType result;
    OSStatus status= SecTrustEvaluate(serverTrust, &result);
    if (status != 0) {
        return isValid;
    }
    isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
    
    return isValid;
}

@end
