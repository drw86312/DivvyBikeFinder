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
@property UILabel *timerLabel;
@property UIButton *startButton;
@property NSMutableArray *buttonsArray;
@property NSDate *initialTime;
@property NSDate *deadline;
@property NSTimeInterval timeInterval;
@property BOOL startButtonSelected;

@end

@implementation TimerViewController

-(void)viewDidLoad
{
    [super viewDidLoad];

    // Set up notification center observers for updating timer after the app re-enters foreground.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterInBackGround) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

    // Set the start button boolean to NO.
    self.startButtonSelected = NO;

    // Create the views
    [self createViews];
}

- (void)applicationWillEnterInBackGround{
    NSLog(@"Application entered background");
}

- (void)applicationWillEnterInForeground
{
    NSLog(@"Application entered foreground");

    // If initial time has been set, the timer is running.
    if (self.initialTime) {

        //Find the current point in time and find the amount of time that's elapsed since the timer was started (self.initialTime) and now.
        NSDate *now = [NSDate date];
        NSTimeInterval interval = [now timeIntervalSinceDate:self.initialTime];

        // If the amount of time that's elapsed is greater than the amount that was left on the clock, the timer has expired
        if (interval > self.timeInterval) {

            // Shutdown the timer and style the views
            self.initialTime = nil;
            self.deadline = nil;
            [self.timer invalidate];
            self.timer = nil;
            [self enableButtons];
            self.timerLabel.text = [NSString stringWithFormat:@"00:00"];

            // Style start button
            self.startButton.enabled = NO;
            [self.startButton setTitle:@"Times Up!" forState:UIControlStateNormal];
            [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.startButton setBackgroundColor:[UIColor walkRouteColor]];
        }

        // else, the timer is still running, but the time on the clock should be updated.
        else {
            self.timeInterval = [self.deadline timeIntervalSinceNow];
        }
    }
}

#pragma mark - UICreation

-(void)createViews
{
    // Find status and navigation bar heights
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
//    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;

    // Set frame values for drawing views
    CGFloat verticalOffset = statusBarHeight + navBarHeight + 10.0f;
    CGFloat horizontalOffset = 10.0f;
    CGFloat startButtonWidth = self.view.frame.size.width - 20.0f;
    CGFloat startButtonHeight = 122.0f;

    // Create and style the timer label
    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, startButtonWidth, startButtonHeight)];
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    self.timerLabel.text = [NSString stringWithFormat:@"00:00"];
    self.timerLabel.textColor = [UIColor divvyColor];
    self.timerLabel.layer.borderWidth = 2.0f;
    self.timerLabel.layer.borderColor = [[UIColor divvyColor] CGColor];
    self.timerLabel.font = [UIFont systemFontOfSize:90.0f];
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

    // Set button width and spacing
    CGFloat spacing = 5.0f;
    CGFloat buttonWidth = (startButtonWidth - ((self.buttonsArray.count -1) * spacing)) / self.buttonsArray.count;
    CGFloat buttonHeight = buttonWidth;

    // Iterate through all the buttons, place them on the view and style them.
    for (UIButton *button in self.buttonsArray) {
        button.frame = CGRectMake(horizontalOffset, verticalOffset, buttonWidth, buttonHeight);
        button.layer.cornerRadius = 5.0f;
        button.layer.borderWidth = 2.0f;
        button.layer.borderColor = [[UIColor walkRouteColor] CGColor];
        button.titleLabel.font = [UIFont systemFontOfSize:24.0f];
        button.titleLabel.numberOfLines = 0;
        [button setTitleColor:[UIColor walkRouteColor] forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:button];

        horizontalOffset += button.frame.size.width + spacing;
    }

    verticalOffset += buttonHeight + 10.0f;
    horizontalOffset = 10.0f;

    // Create and style the "Start" button
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, startButtonWidth, startButtonHeight)];
    [self.startButton setBackgroundColor:[UIColor divvyColor]];
    self.startButton.layer.cornerRadius = 5.0f;
    self.startButton.titleLabel.font = [UIFont systemFontOfSize:65.0f];
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.startButton addTarget:self
                action:@selector(startButtonSelected:)
      forControlEvents:UIControlEventTouchUpInside];
    self.startButton.enabled = NO;
    [self.view addSubview:self.startButton];
}

#pragma mark - IBActions

-(void)startButtonSelected:(id)sender
{
   // Should run when the button is canceling the timer/stopwatch
    if (self.startButtonSelected) {

        // Eliminate timer, set Date objects to nil.
        [self.timer invalidate];
        self.timer = nil;
        self.deadline = nil;
        self.initialTime = nil;

        // Enable selection buttons, disable start button.
        [self enableButtons];
        self.startButton.enabled = NO;

        // Style the start button
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
        [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.startButton setBackgroundColor:[UIColor divvyColor]];

        // Style the timer label
        self.timerLabel.text = [NSString stringWithFormat:@"00:00"];
        self.timerLabel.textColor = [UIColor divvyColor];
        self.timerLabel.layer.borderWidth = 2.0f;
        self.timerLabel.layer.borderColor = [[UIColor divvyColor] CGColor];
        self.timerLabel.backgroundColor = [UIColor whiteColor];
    }

    // Should run when button is starting the timer
    else {
        // Disable time selection buttons
        [self disableButtons];

        // Start timer
        [self createTimer];

        // Set the point in time when the timer is created. Set the point in time when the timer will expire.
        self.initialTime = [NSDate date];
        self.deadline = [self.initialTime dateByAddingTimeInterval:self.timeInterval];

        // Style start button
        [self.startButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self.startButton setTitleColor:[UIColor divvyColor] forState:UIControlStateNormal];
        self.startButton.backgroundColor = [UIColor whiteColor];
        self.startButton.layer.borderWidth = 2.0f;
        self.startButton.layer.borderColor = [[UIColor divvyColor] CGColor];

        // Style timer label
        self.timerLabel.textColor = [UIColor whiteColor];
        self.timerLabel.layer.borderWidth = 0.0f;
        self.timerLabel.backgroundColor = [UIColor divvyColor];
    }
    // Switch start button selected boolean
    self.startButtonSelected = !self.startButtonSelected;
}

-(void)button1Selected:(id)sender
{
    self.timeInterval = 60 * 15;
    self.timerLabel.text = @"15:00";
    self.startButton.enabled = YES;
    self.startButtonSelected = NO;

    // Style start button
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor divvyColor]];
    self.startButton.layer.borderWidth = 2.0f;
}

-(void)button2Selected:(id)sender
{
    self.timeInterval = 60 * 30;
    self.timerLabel.text = @"30:00";
    self.startButton.enabled = YES;
    self.startButtonSelected = NO;

    // Style start button
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor divvyColor]];
    self.startButton.layer.borderWidth = 2.0f;
}

-(void)button3Selected:(id)sender
{
    self.timeInterval = 60 * 45;
    self.timerLabel.text = @"45:00";
    self.startButton.enabled = YES;
    self.startButtonSelected = NO;

    // Style start button
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor divvyColor]];
    self.startButton.layer.borderWidth = 2.0f;
}

-(void)button4Selected:(id)sender
{
    self.timeInterval = 60 * 60;
    self.timerLabel.text = @"60:00";
    self.startButton.enabled = YES;
    self.startButtonSelected = NO;

    // Style start button
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor divvyColor]];
    self.startButton.layer.borderWidth = 2.0f;
}

# pragma mark - timer methods

-(void)createTimer
{
    // Create timer with firing interval of one second.
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
}

-(void)timer:(NSTimer *)timer
{
    // Reduce the time interval by one second
    self.timeInterval -= 1.0;

    // Set the seconds integer to be timeInterval modulo 60.
    NSInteger intTimeInterval = self.timeInterval;
    NSInteger seconds = intTimeInterval % 60;

    // Set the minutes integer to be timeInterval divided by 60, modulo 60.
    NSInteger minutes = (intTimeInterval/60) % 60;

    // Customize the timerLabel text to show two zeros instead of 1.
    if (seconds < 10) {
        self.timerLabel.text = [NSString stringWithFormat:@"%ld:0%ld", (long)minutes, (long)seconds];
    }
    else {
        self.timerLabel.text = [NSString stringWithFormat:@"%ld:%ld", (long)minutes, (long)seconds];
    }

    // When minutes hits zero, invalidate the timer and style the view.
    if (minutes == 0) {
        [self.timer invalidate];
        self.timer = nil;
        self.initialTime = nil;
        self.deadline = nil;
        [self enableButtons];
        self.timerLabel.text = [NSString stringWithFormat:@"00:00"];

        // Style start button
        self.startButton.enabled = NO;
        [self.startButton setTitle:@"Times Up!" forState:UIControlStateNormal];
        [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.startButton setBackgroundColor:[UIColor walkRouteColor]];
        self.startButton.layer.borderWidth = 0.0f;
    }
}

#pragma mark - helper methods

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


@end
