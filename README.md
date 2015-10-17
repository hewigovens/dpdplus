### DPDPlus

DPDPlus is a utility for so-called HTTP DNS resolving, based on the API from [Dnspod](https://www.dnspod.cn/httpdns).

### Interface

```objc
@interface DPDPlus : NSObject

// DNSPod http request timeout
+ (void)setRequestTimeout:(NSTimeInterval)timeout;

// Domains to resolve
+ (void)registerDomains:(NSArray *)domains;

// Force update cache
+ (void)updateCache;

// IP addresses for domain
+ (NSArray *)ipAddressesForDomain:(NSString *)domain;

// Update HTTP request, replace domain with ip, set Host header
+ (void)applyHTTPDNSForRequest:(NSMutableURLRequest *)request;

// Helper method for HTTPS request used in delegate method
// -(void)connection:willSendRequestForAuthenticationChallenge
// -(void)URLSession:didReceiveChallenge:completionHandler:
+ (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain;

// Timestamp mach_absolute_time
+ (NSTimeInterval)now;
@end
```

### How to use

```objc

//setup DPDPlus will update ips automatically
[DPDPlus registerDomains:@[@"api.github.com"]];

//query 
[DPDPlus ipAddressesForDomain:@"api.github.com"]

```

see `DPDplusTests` for more details

### TODO
* leverage `NSURLProtocol`
* Pod / Carthage