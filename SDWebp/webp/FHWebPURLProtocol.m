//
//  FHWebPURLProtocol.m
//
//  Created by Suzq on 16/6/22.
//  Copyright  2017年 Suzq All rights reserved.
//

#import "FHWebPURLProtocol.h"
#import "UIImage+MultiFormat.h"
#import "NSData+ImageContentType.h"


static NSString *URLProtocolHandledKey = @"URLHasHandle";

@interface FHWebPURLProtocol()<NSURLSessionDelegate,NSURLSessionDataDelegate>

@property (nonatomic,strong) NSURLSession *session;
@property (strong, nonatomic) NSMutableData *imageData;
@property (nonatomic) BOOL beginAppendData;

@end

@implementation FHWebPURLProtocol

#pragma mark 初始化请求




+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    ///通过UA 只拦截WebView 发起的请求
    NSString* userAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    if ([userAgent rangeOfString:@"AppleWebKit/"].location == NSNotFound)
    {
        return NO;
    }
 
    //判断是否为wep格式
    if (![FHWebPURLProtocol isWebPURL:request])
    {
        
        return NO;
    }
    
    //只处理http和https请求
    NSString *scheme = [[request URL] scheme];
    if ( [scheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)
    {
        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

#pragma mark 通信协议内容实现

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableReqeust];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue currentQueue]];
    [[self.session dataTaskWithRequest:mutableReqeust] resume];
    
}

- (void)stopLoading
{
    [self.session invalidateAndCancel];
}

#pragma mark - dataDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSMutableURLRequest *    redirectRequest;
    
    redirectRequest = [newRequest mutableCopy];
    [[self class] removePropertyForKey:URLProtocolHandledKey inRequest:redirectRequest];
    
    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    [self.session invalidateAndCancel];
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
    self.imageData = [[NSMutableData alloc] initWithCapacity:expected];
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{

    //if ([FHWebPURLProtocol isWebPURL:dataTask.currentRequest]) {
        self.beginAppendData = YES;
        [self.imageData appendData:data];
    //}
    if (!_beginAppendData) {
        [self.client URLProtocol:self didLoadData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    
    //NSLog(@"webp---%@",task.currentRequest.URL);
    
    if (error)
    {
        [self.client URLProtocol:self didFailWithError:error];
    
    }else
    {
        if ([FHWebPURLProtocol isWebURL:self.imageData])
        {
           // NSLog(@"webp---%@",task.currentRequest.URL);

            UIImage *imgData = [UIImage sd_imageWithData:self.imageData];
            NSData *transData = UIImageJPEGRepresentation(imgData, 0.8f);
            self.beginAppendData = NO;
            self.imageData = nil;
            [self.client URLProtocol:self didLoadData:transData];
        }
        
        @try
        {
              [self.client URLProtocolDidFinishLoading:self];
            
        }@catch (NSException * e)
        {
            //异常处理代码
        }
      
    }
    
}
//判断是否web url
+(BOOL)isWebURL:(NSData *)data
{
    NSString *imageContentType = [NSData sd_contentTypeForImageData:data];
    if ([imageContentType isEqualToString:@"image/webp"])
    {
        return YES;
    }
    return NO;
}

//判断是否为webp url
+(BOOL)isWebPURL:(NSURLRequest *)request
{
      return YES;
//    //如果 需要加强处理   服务端返回格式 带有@"format=webp"。 不用这个判断也是可以的
//    if ([request.URL.absoluteString rangeOfString:@"format=webp"].location == NSNotFound)
//    {
//        return NO;
//    }
//    return YES;
}

@end
