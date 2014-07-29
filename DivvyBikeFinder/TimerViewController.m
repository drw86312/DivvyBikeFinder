//
//  TimerViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 7/28/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "TimerViewController.h"
#import "UIColor+DesignColors.h"
#import <AudioToolbox/AudioToolbox.h>

@interface TimerViewController () <UITextFieldDelegate>

@property NSTimer *timer;
@property NSInteger initialTime;
@property NSInteger seconds;
@property NSInteger minutes;
@property UILabel *timerLabel;
@property UIButton *startButton;
@property NSMutableArray *buttonsArray;
@property BOOL startButtonSelected;

@end

@implementation TimerViewController


-(void)viewDidLoad
{
    [super viewDidLoad];

    self.startButtonSelected = NO;
    self.initialTime = 60 * 30;
    self.minutes = 30 -1;

    [self setStyle];
    [self createViews];
}


-(void)createViews
{
    // Find status and navigation bar heights
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;

    // Set frame values for drawing views
    CGFloat verticalOffset = statusBarHeight + navBarHeight + 10.0f;
    CGFloat horizontalOffset = 10.0f;
    CGFloat startButtonWidth = self.view.frame.size.width - 20.0f;
    CGFloat startButtonHeight = 60.0f;

    // Create and style the timer label
    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, startButtonWidth, startButtonHeight)];
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    self.timerLabel.text = [NSString stringWithFormat:@"30:00"];
    self.timerLabel.textColor = [UIColor divvyColor];
    self.timerLabel.layer.borderWidth = 1.0f;
    self.timerLabel.layer.borderColor = [[UIColor divvyColor] CGColor];
    self.timerLabel.font = [UIFont systemFontOfSize:30.0f];
    [self.view addSubview:self.timerLabel];

    verticalOffset += self.timerLabel.frame.size.height + 10.0f;

    // Create buttons and place them into an array.
    self.buttonsArray = [NSMutableArray new];

    UIButton *button1 = [[UIButton alloc] init];
    UIButton *button2 = [[UIButton alloc] init];
    UIButton *button3 = [[UIButton alloc] init];
    UIButton *button4 = [[UIButton alloc] init];
    [self.buttonsArray addObject:button1];
    [self.buttonsArray addObject:button2];
    [self.buttonsArray addObject:button3];
    [self.buttonsArray addObject:button4];

    // Set button width and spacing
    CGFloat spacing = 5.0f;
    CGFloat buttonWidth = (startButtonWidth - ((self.buttonsArray.count -1) * spacing)) / self.buttonsArray.count;

    // Iterate through all the buttons, place them on the view and style them.
    for (UIButton *button in self.buttonsArray) {
        button.frame = CGRectMake(horizontalOffset, verticalOffset, buttonWidth, startButtonHeight);
        button.layer.cornerRadius = 5.0f;
        button.layer.borderWidth = 1.0f;
        button.layer.borderColor = [[UIColor walkRouteColor] CGColor];
        button.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        button.titleLabel.numberOfLines = 0;
        [button setTitleColor:[UIColor walkRouteColor] forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:button];

        horizontalOffset += button.frame.size.width + spacing;
    }

    // Set button titles
    [button1 setTitle:@"15\nmin" forState:UIControlStateNormal];
    [button2 setTitle:@"30\nmin" forState:UIControlStateNormal];
    [button3 setTitle:@"45\nmin" forState:UIControlStateNormal];
    [button4 setTitle:@"60\nmin" forState:UIControlStateNormal];

    // Set button selector methods
    [button1 addTarget:self
                action:@selector(button1Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [button2 addTarget:self
                action:@selector(button2Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [button3 addTarget:self
                action:@selector(button3Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [button4 addTarget:self
                action:@selector(button4Selected:)
      forControlEvents:UIControlEventTouchUpInside];


    verticalOffset += startButtonHeight + 10.0f;
    horizontalOffset = 10.0f;

    // Create and style the "Start" button
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, startButtonWidth, startButtonHeight)];
    [self.startButton setBackgroundColor:[UIColor divvyColor]];
    self.startButton.layer.cornerRadius = 5.0f;
    self.startButton.titleLabel.font = [UIFont systemFontOfSize:30.0f];
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.startButton addTarget:self
                action:@selector(startButtonSelected:)
      forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];
}

-(void)startButtonSelected:(id)sender
{
    if (self.startButtonSelected) {
        // Eliminate timer
        [self.timer invalidate];
        self.timer = nil;

        // Set back to default time of 30 minutes.
        self.initialTime = 60 * 30;
        self.minutes = 30 -1;
        self.timerLabel.text = @"30:00";

        // Make buttons selectable.
        [self enableButtons];

        // Style the start button
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
        [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.startButton setBackgroundColor:[UIColor divvyColor]];

        // Style the timer label
        self.timerLabel.textColor = [UIColor divvyColor];
        self.timerLabel.layer.borderWidth = 1.0f;
        self.timerLabel.layer.borderColor = [[UIColor divvyColor] CGColor];
        self.timerLabel.backgroundColor = [UIColor whiteColor];
    }
    else {
        // Disable buttons
        [self disableButtons];

        // Start timer
        [self createTimer];

        // Style start button
        [self.startButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self.startButton setTitleColor:[UIColor divvyColor] forState:UIControlStateNormal];
        self.startButton.backgroundColor = [UIColor whiteColor];
        self.startButton.layer.borderWidth = 1.0f;
        self.startButton.layer.borderColor = [[UIColor divvyColor] CGColor];

        self.timerLabel.textColor = [UIColor whiteColor];
        self.timerLabel.layer.borderWidth = 0.0f;
        self.timerLabel.backgroundColor = [UIColor divvyColor];
    }

    self.startButtonSelected = !self.startButtonSelected;
}

-(void)button1Selected:(id)sender
{
    self.initialTime = 60 * 15;
    self.minutes = 15 -1;
    self.timerLabel.text = @"15:00";
}

-(void)button2Selected:(id)sender
{
    self.initialTime = 60 * 30;
    self.minutes = 30 -1;
    self.timerLabel.text = @"30:00";
}

-(void)button3Selected:(id)sender
{
    self.initialTime = 60 * 45;
    self.minutes = 45 -1;
    self.timerLabel.text = @"45:00";
}

-(void)button4Selected:(id)sender
{
    self.initialTime = 60 * 60;
    self.minutes = 60 -1;
    self.timerLabel.text = @"60:00";
}

-(void)disableButtons
{
    for (UIButton *button in self.buttonsArray) {
        button.enabled = NO;
    }
}

-(void)enableButtons
{
    for (UIButton *button in self.buttonsArray) {
        button.enabled = YES;
    }
}


-(void)createTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
}

-(void)timer:(NSTimer *)timer
{
    // Reduce the initial time by one second
    self.initialTime -= 1.0;

    // Set the seconds integer to be initial time modulo 60.
    self.seconds = self.initialTime % 60;

    // When seconds hits zero, reduce the minute variable by one.
    if (self.seconds == 0) {
        self.timerLabel.text = [NSString stringWithFormat:@"%ld:0%ld", (long)self.minutes, self.seconds];
        self.minutes -= 1;
    }
    else if (self.seconds < 10) {
        // Customize the timerLabel text to show two zeros instead of 1.
        self.timerLabel.text = [NSString stringWithFormat:@"%ld:0%ld", (long)self.minutes, self.seconds];
    }
    else {
        self.timerLabel.text = [NSString stringWithFormat:@"%ld:%ld", (long)self.minutes, (long)self.seconds];
    }

    // When minutes hits zero, invalidate the timer.
    if (self.minutes == -1) {
        [self.timer invalidate];
        self.timer = nil;
        [self enableButtons];
        self.initialTime = 60 * 30;
        self.minutes = 30 -1;
        self.timerLabel.text = [NSString stringWithFormat:@"30:00"];
    }
}

-(void)setStyle
{
    
}



@end
