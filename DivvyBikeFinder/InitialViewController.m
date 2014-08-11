//
//  InitialViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 7/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "InitialViewController.h"
#import "UIColor+DesignColors.h"
#import "UIFont+DesignFonts.h"

@interface InitialViewController ()

@end

@implementation InitialViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setStyle];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self performSegueWithIdentifier:@"onward" sender:self];
}

-(void)setStyle
{
    // View
    self.view.backgroundColor = [UIColor divvyColor];

    // ImageView
    CGFloat spacing = 10.0f;
    CGFloat imageViewWidth = 160.0;
    CGFloat imageViewHeight = imageViewWidth;
    CGFloat horizontalOffset = (self.view.frame.size.width/2) - (imageViewWidth/2);
    CGFloat verticalOffset = (self.view.frame.size.height/2) - (imageViewHeight/2);

    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    logo.image = [UIImage imageNamed:@"logo"];
    [self.view addSubview:logo];

    CGFloat labelWidth = 300.0f;
    CGFloat labelHeight = 50.0f;
    horizontalOffset = (self.view.frame.size.width/2) - (labelWidth/2);
    verticalOffset =logo.frame.origin.y - spacing - labelHeight;

    // Labels
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    topLabel.text = @"Divvy";
    topLabel.font = [UIFont hugeFontBold];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.textColor = [UIColor blackColor];
    [self.view addSubview:topLabel];

    verticalOffset = logo.frame.origin.y + imageViewHeight + spacing;

    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    bottomLabel.text = @"& Conquer";
    bottomLabel.font = [UIFont hugeFontBold];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.textColor = [UIColor blackColor];
    [self.view addSubview:bottomLabel];
}


@end
