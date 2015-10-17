//
//  DPDplusTests.m
//  DPDplusTests
//
//  Created by hewigovens on 10/17/15.
//  Copyright © 2015 hewigovens. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DPDPlus.h"

@interface DPDplusTests : XCTestCase<NSURLConnectionDelegate, NSURLSessionDelegate>
@property (nonatomic, strong) NSArray *testDomains;
@property (nonatomic, strong) NSString *testAPI;
@property (nonatomic, strong) NSURLConnection *testUrlConnection;
@property (nonatomic, strong) XCTestExpectation *testUrlConnectionExpect;
@end

@implementation DPDplusTests

- (void)setUp {
    [super setUp];
    
    self.testDomains = @[@"api.github.com", @"google.com"];
    self.testAPI = @"https://api.github.com/users/hewigovens/repos";
    [DPDPlus registerDomains:self.testDomains];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testResolveRecord {
    XCTestExpectation *expect = [self expectationWithDescription:@"ip addressee for test domain not empty"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (NSString *domain in self.testDomains) {
            NSArray *array = [DPDPlus ipAddressesForDomain:domain];
            NSLog(@"get ips for %@", domain);
            NSLog(@"%@", array);
            XCTAssertGreaterThan(array.count, 0);
        }
        [expect fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testURLConnectionHttpsRequest {
    XCTestExpectation *expect = [self expectationWithDescription:@"list user repo success using NSURLConnection"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:self.testAPI];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [DPDPlus applyHTTPDNSForRequest:request];
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        self.testUrlConnection = connection;
        self.testUrlConnectionExpect = expect;
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testURLSessionHttpsRequest {
    XCTestExpectation *expect = [self expectationWithDescription:@"list user repo success using NSURLSession"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:self.testAPI];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [DPDPlus applyHTTPDNSForRequest:request];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            XCTAssertGreaterThan(data.length, 0);
            NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"%@", [json firstObject]);
            [expect fulfill];
        }];
        [task resume];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([DPDPlus evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == self.testUrlConnection) {
        XCTAssertGreaterThan(data.length, 0);
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSLog(@"%@", [json firstObject]);
        [self.testUrlConnectionExpect fulfill];
    }
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    if ([DPDPlus evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    }
}

@end
