//
//  ViewController.m
//  SDWebp
//
//  Created by suzq on 2017/7/31.
//  Copyright © 2017年 suzq. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.webView=  [[UIWebView alloc] initWithFrame:self.view.bounds];
    //self.webView.delegate = self;
    
    [self.view addSubview:self.webView];
    
    
    NSString *webpURL=@"https://www.baidu.com";
    
    NSURL* url = [NSURL URLWithString:webpURL];//创建URL
    NSURLRequest* request = [NSURLRequest requestWithURL:url];//创建NSURLRequest
    [self.webView loadRequest:request];//加载

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
