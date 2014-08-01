//
//  WebviewViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 8/1/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "WebviewViewController.h"

@interface WebviewViewController ()

@property UIWebView *webView;

@end

@implementation WebviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.x, self.view.frame.size.width, self.view.frame.size.height)];


    if (self.yelpLocationFromSourceVC.businessMobileURL) {
        NSURL *mobileURL = [NSURL URLWithString:self.yelpLocationFromSourceVC.businessMobileURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:mobileURL];
        [self.webView loadRequest:request];
        NSLog(@"mobileURL");
    }
    else if (self.yelpLocationFromSourceVC.businessURL)
    {
        NSURL *businessURL = [NSURL URLWithString:self.yelpLocationFromSourceVC.businessURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:businessURL];
        [self.webView loadRequest:request];        NSLog(@"webURL");

    }
    else {
        self.webView.hidden = YES;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ appears to not have a webpage", self.yelpLocationFromSourceVC.name] message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        NSLog(@"neither");
    }

    [self.view addSubview:self.webView];

}





@end
