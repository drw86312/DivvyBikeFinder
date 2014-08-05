//
//  WebviewViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 8/1/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "WebviewViewController.h"
#import "UIColor+DesignColors.h"

@interface WebviewViewController () <UIWebViewDelegate>

@property UIWebView *webView;

@property UIActivityIndicatorView *activityIndicator;

@end

@implementation WebviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Divvy & Conquer";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.x, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.webView];
    self.webView.delegate = self;

    // Create the activity indicator
    CGFloat indicatorWidth = 50.0f;
    CGFloat indicatorHeight = 50.0f;

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.frame = CGRectMake((self.view.frame.size.width/2) - (indicatorWidth/2), (self.view.frame.size.height/2) - (indicatorHeight/2), indicatorWidth, indicatorHeight);
    self.activityIndicator.color = [UIColor walkRouteColor];
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    [self.view addSubview:self.activityIndicator];


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
        [self.webView loadRequest:request];
        NSLog(@"webURL");
    }
    else {
        self.webView.hidden = YES;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ appears to not have a webpage", self.yelpLocationFromSourceVC.name] message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        NSLog(@"neither");
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"Page loaded");
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}





@end
