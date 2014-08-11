//
//  RouteDetailsViewController.m
//  Divvy & Conquer
//
//  Created by David Warner on 8/6/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "RouteDetailsViewController.h"
#import "UIColor+DesignColors.h"
#import "UIFont+DesignFonts.h"

@interface RouteDetailsViewController ()

@property (strong, nonatomic) UIImageView *directionImageView;
@property (strong, nonatomic) UIImageView *transportTypeImageView;
@property (strong, nonatomic) UILabel *routeStepLabel;
@property NSInteger swipeIndex;

@end

@implementation RouteDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createViews];

    // Set navigation bar title label
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat labelWidth = 200.0f;
    CGFloat labelHeight = 25.0f;
    CGFloat horizontalOffset = (self.view.frame.size.width/2) - (labelWidth/2);
    CGFloat verticalOffset = statusBarHeight + (navBarHeight/2);
    UILabel *navigationBarLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];

    navigationBarLabel.text = @"Route Details";
    navigationBarLabel.textColor = [UIColor whiteColor];
    navigationBarLabel.textAlignment = NSTextAlignmentCenter;
    navigationBarLabel.font = [UIFont bigFontBold];
    self.navigationItem.titleView = navigationBarLabel;

    self.navigationController.navigationBar.tintColor = [UIColor divvyColor];

    // Iterate through all the dictionaries until the once matching the one selected by the user is found...
    NSInteger counter = 0;
    for (NSDictionary *dictionary in self.routeDictionaries) {
        if ([dictionary isEqualToDictionary:self.selectedRouteDictionary]) {

            // Find instances of 'left', 'right', 'continue', and 'proceed' and set appropriate direction image.
            NSString *instructions = [dictionary objectForKey:@"instructions"];
            if ([instructions rangeOfString:@"right"].location == NSNotFound) {
                NSLog(@"string does not contain right");
                }
                else {
                    self.directionImageView.image = [UIImage imageNamed:@"rightturn"];
                NSLog(@"string contains right!");
                }
                if ([instructions rangeOfString:@"left"].location == NSNotFound) {
                    NSLog(@"string does not contain left");
                }
                else {
                    self.directionImageView.image = [UIImage imageNamed:@"leftturn"];
                    NSLog(@"string contains right!");
                }
                if ([instructions rangeOfString:@"continue"].location == NSNotFound) {
                    NSLog(@"string does not contain left");
                }
                else {
                    self.directionImageView.image = [UIImage imageNamed:@"straightarrow"];
                    NSLog(@"string contains continue!");
                }
                if ([instructions rangeOfString:@"Proceed"].location == NSNotFound) {
                    NSLog(@"string does not contain proceed");
                }
                else {
                    self.directionImageView.image = [UIImage new];
                    NSLog(@"string contains proceed!");
                }

            // Find the transport type and set the appropriate imageview and background color.
            if ([[dictionary objectForKey:@"transportType"] isEqualToString:@"walking"]) {
                self.view.backgroundColor = [UIColor walkRouteColor];
                self.transportTypeImageView.image = [UIImage imageNamed:@"Walking"];
            }
            else {
                self.view.backgroundColor = [UIColor divvyColor];
                self.transportTypeImageView.image = [UIImage imageNamed:@"bicycle"];
            }

            // Find the right units for the distance string
            NSString *distanceString = [NSString new];
            if ([[dictionary objectForKey:@"distance"] floatValue] < 170.0f) {
                CGFloat distance = [[dictionary objectForKey:@"distance"] floatValue] * 3.28084;
                distanceString = [NSString stringWithFormat:@"%.0f feet", distance];
            }
            else {
                CGFloat distance = [[dictionary objectForKey:@"distance"] floatValue] * 0.000621371;
                distanceString = [NSString stringWithFormat:@"%.01f miles", distance];
            }

            // The first element of the leg of route always has 0.00 distance, so don't display it
            if ([[dictionary objectForKey:@"distance"] floatValue] == 0.0f) {
                self.routeStepLabel.text = [dictionary objectForKey:@"instructions"];
            }

            // Keep "the destination" if it's the last element in the array, else replace with 'Divvy Station'
            else if (![dictionary isEqual:[self.routeDictionaries lastObject]]) {

                // Find the instructions string
                NSString *instructions = [dictionary objectForKey:@"instructions"];

                // Replace upper case "The destination"
                NSString *instructionsNew = [instructions stringByReplacingOccurrencesOfString:@"The destination" withString:@"Divvy Station"];

                // Replace lower case "the destination"
                NSString *instructionsNew2 = [instructionsNew stringByReplacingOccurrencesOfString:@"the destination" withString:@"Divvy Station"];
                self.routeStepLabel.text = [NSString stringWithFormat:@"%@\nin\n%@", instructionsNew2, distanceString];
            }
            // Should be the last dictionary in the steps array...
            else {
                self.routeStepLabel.text = [NSString stringWithFormat:@"%@\nin\n%@", [dictionary objectForKey:@"instructions"], distanceString];
                self.transportTypeImageView.image = [UIImage imageNamed:@"endguy"];
                self.view.backgroundColor = [UIColor greenColor];
            }

            // If its the Divvy Step, show the Divvy image
            if ([self.routeStepLabel.text rangeOfString:@"Divvy"].location == NSNotFound) {
                NSLog(@"string does not contain Divvy");
            }
            else {
                self.transportTypeImageView.image = [UIImage imageNamed:@"DivvyLogo"];
                self.view.backgroundColor = [UIColor blackColor];
            }

        // When counter finds the right dictionary, assign the swipe index to the counter value.
        self.swipeIndex = counter;
        break;
        }
        else {
            counter += 1;
        }
    }

    NSLog(@"Selected Route Dictionary: %@",self.selectedRouteDictionary);
    NSLog(@"Route Dictionaries: %@",self.routeDictionaries);
    NSLog(@"Route Dictionaries Count: %lu",(unsigned long)self.routeDictionaries.count );

    // Add the swipe gesture recoginzer to the view
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeLeft];
    [self.view addGestureRecognizer:swipeRight];
}

-(void)createViews;
{
    CGFloat margin = 10.0f;
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat imageViewWidth = 75.0f;
    CGFloat imageViewHeight = imageViewWidth;
    CGFloat horizontalOffset = (self.view.frame.size.width/2) - (imageViewWidth/2);
    CGFloat verticalOffset = navBarHeight + statusBarHeight + margin;

    self.transportTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    [self.view addSubview:self.transportTypeImageView];

    verticalOffset = self.view.frame.size.height - tabBarHeight - margin - imageViewHeight;
    self.directionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset , imageViewWidth, imageViewHeight)];
    [self.view addSubview:self.directionImageView];


    CGFloat indicatorImageViewWidth = 25.0f;
    CGFloat indicatorImageViewHeight = 80.0f;
    horizontalOffset = (margin/2);
    verticalOffset = (self.view.frame.size.height/2) - (indicatorImageViewHeight/2);

    UIImageView *leftSwipeIndicatorView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, indicatorImageViewWidth, indicatorImageViewHeight)];
    leftSwipeIndicatorView.image = [UIImage imageNamed:@"leftindicator"];
    [self.view addSubview:leftSwipeIndicatorView];

    horizontalOffset = (self.view.frame.size.width - (margin/2) - indicatorImageViewWidth);

    UIImageView *rightSwipeIndicatorView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, indicatorImageViewWidth, indicatorImageViewHeight)];
    rightSwipeIndicatorView.image = [UIImage imageNamed:@"rightindicator"];
    [self.view addSubview:rightSwipeIndicatorView];


    CGFloat labelWidth = self.view.frame.size.width - (2*indicatorImageViewWidth) - (2 * margin);
    CGFloat labelHeight = 190.0f;
    verticalOffset = (self.view.frame.size.height/2) - (labelHeight/2) + 8.0f;
    horizontalOffset = (self.view.frame.size.width/2) - (labelWidth/2);

    self.routeStepLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    self.routeStepLabel.font = [UIFont bigHugeFontBold];
    self.routeStepLabel.textColor = [UIColor whiteColor];
    self.routeStepLabel.numberOfLines = 0;
    self.routeStepLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.routeStepLabel];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe
{
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        if (self.swipeIndex == self.routeDictionaries.count -1) {
            NSLog(@"Farthest Right");
            }
        else {
            self.swipeIndex += 1;

            // Find instances of 'left', 'right', 'continue', and 'proceed' and set appropriate direction image.
            NSString *instructions = [[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"instructions"];
            if ([instructions rangeOfString:@"right"].location == NSNotFound) {
                NSLog(@"string does not contain right");
            }
            else {
                self.directionImageView.image = [UIImage imageNamed:@"rightturn"];
                NSLog(@"string contains right!");
            }
            if ([instructions rangeOfString:@"left"].location == NSNotFound) {
                NSLog(@"string does not contain left");
            }
            else {
                self.directionImageView.image = [UIImage imageNamed:@"leftturn"];
                NSLog(@"string contains right!");
            }
            if ([instructions rangeOfString:@"continue"].location == NSNotFound) {
                NSLog(@"string does not contain left");
            }
            else {
                self.directionImageView.image = [UIImage imageNamed:@"straightarrow"];
                NSLog(@"string contains continue!");
            }
            if ([instructions rangeOfString:@"Proceed"].location == NSNotFound) {
                NSLog(@"string does not contain proceed");
            }
            else {
                self.directionImageView.image = [UIImage new];
                NSLog(@"string contains proceed!");
            }

            // Find the transport type and set the appropriate imageview and background color.
            if ([[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"transportType"] isEqualToString:@"walking"])
            {
                self.view.backgroundColor = [UIColor walkRouteColor];
                self.transportTypeImageView.image = [UIImage imageNamed:@"Walking"];
            }
            else {
                self.view.backgroundColor = [UIColor divvyColor];
                self.transportTypeImageView.image = [UIImage imageNamed:@"bicycle"];
            }

            // Find the right units for the distance string
            NSString *distanceString = [NSString new];
            if ([[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"distance"] floatValue] < 170.0f) {
                CGFloat distance = [[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"distance"] floatValue] * 3.28084;
                distanceString = [NSString stringWithFormat:@"%.0f feet", distance];
            }
            else {
                CGFloat distance = [[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"distance"] floatValue] * 0.000621371;
                distanceString = [NSString stringWithFormat:@"%.01f miles", distance];
            }

            // The first element of the leg of route always has 0.0 distance, so don't display it
            if ([[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"distance"] floatValue] == 0.0f) {
                self.routeStepLabel.text = [[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"instructions"];
            }
            // Keep "the destination" if it's the last element in the array, else replace with 'Divvy Station'
            else if (![[self.routeDictionaries objectAtIndex:self.swipeIndex] isEqual:[self.routeDictionaries lastObject]]) {
                // Find the instructions string
                NSString *instructions = [[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"instructions"];

                // Replace upper case "The destination"
                NSString *instructionsNew = [instructions stringByReplacingOccurrencesOfString:@"The destination" withString:@"Divvy Station"];

                // Replace lower case "the destination"
                NSString *instructionsNew2 = [instructionsNew stringByReplacingOccurrencesOfString:@"the destination" withString:@"Divvy Station"];
                self.routeStepLabel.text = [NSString stringWithFormat:@"%@\nin\n%@", instructionsNew2, distanceString];
            }

            // Last step in the route instructions
            else {
                self.routeStepLabel.text = [NSString stringWithFormat:@"%@\nin\n%@", [[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"instructions"], distanceString];
                self.transportTypeImageView.image = [UIImage imageNamed:@"endguy"];
                self.view.backgroundColor = [UIColor greenColor];
            }

            // If its the Divvy Step
            if ([self.routeStepLabel.text rangeOfString:@"Divvy"].location == NSNotFound) {
                NSLog(@"string does not contain Divvy");
            }
            else {
                self.transportTypeImageView.image = [UIImage imageNamed:@"DivvyLogo"];
                self.view.backgroundColor = [UIColor blackColor];
            }
        }
    }


    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        if (self.swipeIndex == 0) {
            NSLog(@"Farthest Left");
            }
            else {
                self.swipeIndex -= 1;

                // Find instances of 'left' and 'right' and set appropriate turn arrow.
                NSString *instructions = [[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"instructions"];
                if ([instructions rangeOfString:@"right"].location == NSNotFound) {
                    NSLog(@"string does not contain right");
                }
                else {
                    self.directionImageView.image = [UIImage imageNamed:@"rightturn"];
                    NSLog(@"string contains right!");
                }
                if ([instructions rangeOfString:@"left"].location == NSNotFound) {
                    NSLog(@"string does not contain left");
                }
                else {
                    self.directionImageView.image = [UIImage imageNamed:@"leftturn"];
                    NSLog(@"string contains right!");
                }
                if ([instructions rangeOfString:@"continue"].location == NSNotFound) {
                    NSLog(@"string does not contain left");
                }
                else {
                    self.directionImageView.image = [UIImage imageNamed:@"straightarrow"];
                    NSLog(@"string contains continue!");
                }
                if ([instructions rangeOfString:@"Proceed"].location == NSNotFound) {
                    NSLog(@"string does not contain proceed");
                }
                else {
                    self.directionImageView.image = [UIImage new];
                    NSLog(@"string contains proceed!");
                }

                // Find the transport type and set the appropriate imagview and background color.
                if ([[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"transportType"] isEqualToString:@"walking"])
                {
                    self.view.backgroundColor = [UIColor walkRouteColor];
                    self.transportTypeImageView.image = [UIImage imageNamed:@"Walking"];
                }
                else {
                    self.view.backgroundColor = [UIColor divvyColor];
                    self.transportTypeImageView.image = [UIImage imageNamed:@"bicycle"];
                }


                // Find the right units for the distance string
                NSString *distanceString = [NSString new];
                if ([[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"distance"] floatValue] < 170.0f) {
                    CGFloat distance = [[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"distance"] floatValue] * 3.28084;
                    distanceString = [NSString stringWithFormat:@"%.0f feet", distance];
                }
                else {
                    CGFloat distance = [[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"distance"] floatValue] * 0.000621371;
                    distanceString = [NSString stringWithFormat:@"%.01f miles", distance];
                }

                // The first element of the leg of route always has 0.0 distance, so don't display it
                if ([[[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"distance"] floatValue] == 0.0f) {
                    self.routeStepLabel.text = [[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"instructions"];
                }
                // Keep "the destination" if it's the last element in the array, else replace with 'Divvy Station'
                else if (![[self.routeDictionaries objectAtIndex:self.swipeIndex] isEqual:[self.routeDictionaries lastObject]]) {
                    // Find the instructions string
                    NSString *instructions = [[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"instructions"];

                    // Replace upper case "The destination"
                    NSString *instructionsNew = [instructions stringByReplacingOccurrencesOfString:@"The destination" withString:@"Divvy Station"];

                    // Replace lower case "the destination"
                    NSString *instructionsNew2 = [instructionsNew stringByReplacingOccurrencesOfString:@"the destination" withString:@"Divvy Station"];

                    self.routeStepLabel.text = [NSString stringWithFormat:@"%@\nin\n%@", instructionsNew2, distanceString];
                }

                // Last step in the route instructions
                else {
                    self.routeStepLabel.text = [NSString stringWithFormat:@"%@\nin\n%@", [[self.routeDictionaries objectAtIndex:self.swipeIndex] objectForKey:@"instructions"], distanceString];
                    self.transportTypeImageView.image = [UIImage imageNamed:@"endguy"];
                    self.view.backgroundColor = [UIColor greenColor];
                }

                // If its the Divvy Step
                if ([self.routeStepLabel.text rangeOfString:@"Divvy"].location == NSNotFound) {
                    NSLog(@"string does not contain Divvy");
                }
                else {
                    self.transportTypeImageView.image = [UIImage imageNamed:@"DivvyLogo"];
                    self.view.backgroundColor = [UIColor blackColor];
                }
            }
        }
}


@end
