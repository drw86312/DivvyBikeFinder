//
//  TimerViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 7/28/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "TimerViewController.h"
#import "UIColor+DesignColors.h"
#import "UIFont+DesignFonts.h"
#import <AudioToolbox/AudioToolbox.h>

@interface TimerViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property NSTimer *timer;
@property UILabel *timerLabel;
@property UIButton *startButton;
@property NSMutableArray *buttonsArray;
@property NSMutableArray *buttonsArray2;
@property NSDate *initialTime;
@property NSDate *deadline;
@property NSTimeInterval timeInterval;
@property UILocalNotification *notification;
@property UILabel *notificationInformationLabel;
@property BOOL startButtonSelected;
@property UIButton *notificationbutton1;
@property UIButton *notificationbutton2;
@property UIButton *notificationbutton3;
@property UIButton *notificationbutton4;
@property UIButton *cancelNotificationButton;
@property UIImageView *notificationIndicator1;
@property UIImageView *notificationIndicator2;
@property UIImageView *notificationIndicator3;
@property UIImageView *notificationIndicator4;

@end

@implementation TimerViewController

-(void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Divvy & Conquer";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

    // Set up notification center observers for updating timer after the app re-enters foreground.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterInBackGround) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

    // Set the start button boolean to NO.
    self.startButtonSelected = NO;

    // Create the views
    [self createViews];

    // Instantiate the location notification.
    self.notification = [[UILocalNotification alloc] init];
    NSLog(@"Initial load: %@", self.notification);
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
            [self disableNotificationButtons];
            [self hideIndicatorViews];
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            self.notificationInformationLabel.text = @"Set an alert prior to timer expiration";

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
            self.startButton.layer.borderWidth = 0.0;
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

    // Find status and navigation bar heights
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;

    // Set button width and spacing
    CGFloat margin = 10.0f;
    CGFloat spacing = 5.0f;
    CGFloat horizontalOffset = margin;
    CGFloat buttonWidth = ((self.view.frame.size.width - (2 * margin)) - ((self.buttonsArray.count -1) * spacing)) / self.buttonsArray.count;
    CGFloat buttonHeight = buttonWidth;
    CGFloat verticalOffset = (((self.view.frame.size.height - statusBarHeight + navBarHeight)/2) - (buttonHeight/2) -25);

    // Iterate through all the buttons, place them on the view and style them.
    for (UIButton *button in self.buttonsArray) {
        button.frame = CGRectMake(horizontalOffset, verticalOffset, buttonWidth, buttonHeight);
        button.layer.cornerRadius = 5.0f;
        button.layer.borderWidth = 2.0f;
        button.layer.borderColor = [[UIColor walkRouteColor] CGColor];
        button.titleLabel.font = [UIFont bigFontBold];
        button.titleLabel.numberOfLines = 0;
        [button setTitleColor:[UIColor walkRouteColor] forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:button];

        horizontalOffset += button.frame.size.width + spacing;
    }

    // Set frame values for drawing timer label
    horizontalOffset = margin;
    CGFloat timerLabelHeight = 65.0f;
    CGFloat timerLabelWidth = self.view.frame.size.width - (2 * margin);
    verticalOffset = button1.frame.origin.y - timerLabelHeight - spacing;

    // Create and style the timer label
    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, timerLabelWidth, timerLabelHeight)];
    self.timerLabel.textAlignment = NSTextAlignmentCenter;
    self.timerLabel.text = [NSString stringWithFormat:@"00:00"];
    self.timerLabel.textColor = [UIColor divvyColor];
    self.timerLabel.layer.borderWidth = 2.0f;
    self.timerLabel.layer.borderColor = [[UIColor divvyColor] CGColor];
    self.timerLabel.font = [UIFont hugeFontBold];
    [self.view addSubview:self.timerLabel];

    verticalOffset = button1.frame.origin.y + button1.frame.size.height + spacing;
    CGFloat startButtonWidth = timerLabelWidth;
    CGFloat startButtonHeight = timerLabelHeight;

    // Create and style the "Start" button
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, startButtonWidth, startButtonHeight)];
    [self.startButton setBackgroundColor:[UIColor divvyColor]];
    self.startButton.layer.cornerRadius = 5.0f;
    self.startButton.titleLabel.font = [UIFont hugeFontBold];
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.startButton addTarget:self
                action:@selector(startButtonSelected:)
      forControlEvents:UIControlEventTouchUpInside];
    self.startButton.enabled = NO;
    [self.view addSubview:self.startButton];

    // Set frame values for drawing information label
    verticalOffset = statusBarHeight + navBarHeight + spacing;
    CGFloat infoLabelHeight = (self.timerLabel.frame.origin.y - (2 *spacing)) - navBarHeight - statusBarHeight;
    CGFloat infoLabelWidth = timerLabelWidth;

    UILabel *informationLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, infoLabelWidth, infoLabelHeight)];
    informationLabel.textAlignment = NSTextAlignmentCenter;
    informationLabel.text = @"Divvy Bike trips exceeding 30 minutes incur additional fees. Set timer and alerts below to manage your trip";
    informationLabel.textColor = [UIColor blackColor];
    informationLabel.font = [UIFont smallMediumFontBold];
    informationLabel.numberOfLines = 0;
    [self.view addSubview:informationLabel];

    // Set frame values for notification information label
    horizontalOffset = margin;
    verticalOffset = self.startButton.frame.origin.y + self.startButton.frame.size.height;
    CGFloat notificationInformationLabelHeight = 30.0f;
    CGFloat notificationInformationLabelWidth = timerLabelWidth;

    _notificationInformationLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, notificationInformationLabelWidth, notificationInformationLabelHeight)];
    _notificationInformationLabel.textAlignment = NSTextAlignmentCenter;
    _notificationInformationLabel.text = @"Set an alert prior to timer expiration";
    _notificationInformationLabel.textColor = [UIColor blackColor];
    _notificationInformationLabel.font = [UIFont smallMediumFontBold];
    _notificationInformationLabel.numberOfLines = 0;
    [self.view addSubview:_notificationInformationLabel];

    // Create buttons and place them into an array.
    self.buttonsArray2 = [NSMutableArray new];
    _notificationbutton1 = [[UIButton alloc] init];
    _notificationbutton2 = [[UIButton alloc] init];
    _notificationbutton3 = [[UIButton alloc] init];
    _notificationbutton4 = [[UIButton alloc] init];
    _cancelNotificationButton = [[UIButton alloc] init];
    [self.buttonsArray2 addObject:_notificationbutton1];
    [self.buttonsArray2 addObject:_notificationbutton2];
    [self.buttonsArray2 addObject:_notificationbutton3];
    [self.buttonsArray2 addObject:_notificationbutton4];
    [self.buttonsArray2 addObject:_cancelNotificationButton];
    // Set button titles
    [_notificationbutton1 setTitle:@"1\nmin" forState:UIControlStateNormal];
    [_notificationbutton2 setTitle:@"2\nmin" forState:UIControlStateNormal];
    [_notificationbutton3 setTitle:@"5\nmin" forState:UIControlStateNormal];
    [_notificationbutton4 setTitle:@"10\nmin" forState:UIControlStateNormal];
    [_cancelNotificationButton setTitle:@"Cancel\nAlert" forState:UIControlStateNormal];

    // Set button selector methods
    [_notificationbutton1 addTarget:self
                action:@selector(notificationbutton1Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [_notificationbutton2 addTarget:self
                action:@selector(notificationbutton2Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [_notificationbutton3 addTarget:self
                action:@selector(notificationbutton3Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [_notificationbutton4 addTarget:self
                action:@selector(notificationbutton4Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [_cancelNotificationButton addTarget:self
                            action:@selector(cancelNotificationButtonSelected:)
                  forControlEvents:UIControlEventTouchUpInside];


    verticalOffset = _notificationInformationLabel.frame.origin.y + _notificationInformationLabel.frame.size.height;
    buttonWidth = ((self.view.frame.size.width - (2 * margin)) - ((self.buttonsArray2.count -1) * spacing)) / self.buttonsArray2.count;
    buttonHeight = buttonWidth;

    // Iterate through all the buttons, place them on the view and style them.
    for (UIButton *button in self.buttonsArray2) {
        button.frame = CGRectMake(horizontalOffset, verticalOffset, buttonWidth, buttonHeight);
        button.layer.cornerRadius = 5.0f;
        button.layer.borderWidth = 2.0f;
        button.layer.borderColor = [[UIColor walkRouteColor] CGColor];
        if ([button isEqual:_cancelNotificationButton]) {
            button.titleLabel.font = [UIFont smallFontBold];
        }
        else {
            button.titleLabel.font = [UIFont mediumFontBold];
        }
        button.titleLabel.numberOfLines = 0;
        [button setTitleColor:[UIColor walkRouteColor] forState:UIControlStateNormal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.enabled = NO;
        [self.view addSubview:button];
        horizontalOffset += button.frame.size.width + spacing;
    }

    // Make indictor imageviews
    self.notificationIndicator1 = [UIImageView new];
    self.notificationIndicator2 = [UIImageView new];
    self.notificationIndicator3 = [UIImageView new];
    self.notificationIndicator4 = [UIImageView new];

    NSMutableArray *notificationIndicatorArray = [NSMutableArray new];
    [notificationIndicatorArray addObject:self.notificationIndicator1];
    [notificationIndicatorArray addObject:self.notificationIndicator2];
    [notificationIndicatorArray addObject:self.notificationIndicator3];
    [notificationIndicatorArray addObject:self.notificationIndicator4];

    horizontalOffset = margin + (_notificationbutton1.frame.size.width/1.4);
    verticalOffset = _notificationInformationLabel.frame.origin.y + _notificationInformationLabel.frame.size.height - spacing;
    CGFloat imageViewWidth = _notificationbutton1.frame.size.width/3;
    CGFloat imageViewHeight = imageViewWidth;

    for (UIImageView *imageView in notificationIndicatorArray) {
        imageView.frame = CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight);
        imageView.image = [UIImage imageNamed:@"checkmark"];
        imageView.backgroundColor = [UIColor walkRouteColor];
        imageView.layer.cornerRadius = (imageView.frame.size.width/2);
        imageView.hidden = YES;
        [self.view addSubview:imageView];
        horizontalOffset += _notificationbutton1.frame.size.width + spacing;
    }

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

        // Remove notifications and set notification buttons to enabled.
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        [self disableNotificationButtons];
        [self hideIndicatorViews];
        self.notificationInformationLabel.text = @"Set an alert prior to timer expiration";
        NSLog(@"Cancel timer button selected: %@", self.notification);
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

        //Enable notification buttons
        [self enableNotificationButtons];
        NSLog(@"Start timer button selected: %@", self.notification);
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
   self.startButton.layer.borderWidth = 0.0f;
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
    self.startButton.layer.borderWidth = 0.0f;
}

-(void)button3Selected:(id)sender
{
    self.timeInterval = 60 * 45;
    self.timerLabel.text = @"45:00";
    self.startButton.enabled = YES;
    self.startButtonSelected = NO;
    self.startButton.layer.borderWidth = 0.0f;

    // Style start button
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor divvyColor]];
    self.startButton.layer.borderWidth = 0.0f;
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
    self.startButton.layer.borderWidth = 0.0f;
}

-(void)notificationbutton1Selected:(id)sender
{
    // Establish the correct time interval
    NSTimeInterval timeInterval = self.timeInterval - (1 * 60);

    // Make sure there is enough time left on the clock to set the alert.
    if (timeInterval < 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"Not enough time left on the timer to set that alert" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        NSLog(@"Alert time too close to deadline");
    }
    // Set the proper notification alert parameters
    else {
        NSDate *oneMinToDeadline = [self.initialTime dateByAddingTimeInterval:timeInterval];
        self.notification.fireDate = oneMinToDeadline;
        self.notification.alertBody = @"One minute to timer expiration";
        self.notification.soundName = UILocalNotificationDefaultSoundName;
        self.notification.timeZone = [NSTimeZone defaultTimeZone];
        [[UIApplication sharedApplication] scheduleLocalNotification:self.notification];

        self.notificationInformationLabel.text = @"Alert set for one minute before expiration";

        // Display the indicator check mark
        self.notificationIndicator1.hidden = NO;
        self.notificationbutton1.enabled = NO;

        NSLog(@"Set a notification one minutes before deadline: %@", self.notification);
    }
}

-(void)notificationbutton2Selected:(id)sender
{
    // Establish the correct time interval
    NSTimeInterval timeInterval = self.timeInterval - (2 * 60);

    // Make sure there is enough time left on the clock to set the alert.
    if (timeInterval < 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"Not enough time left on the timer to set that alert" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];    }
    else {

    NSTimeInterval timeInterval = self.timeInterval - (2 * 60);
    NSDate *twoMinToDeadline = [self.initialTime dateByAddingTimeInterval:timeInterval];
    self.notification.fireDate = twoMinToDeadline;
    self.notification.alertBody = @"Two minutes to timer expiration";
    self.notification.soundName = UILocalNotificationDefaultSoundName;
    self.notification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:self.notification];

    self.notificationInformationLabel.text = @"Alert set for two minutes before expiration";

    // Display the indicator check mark
    self.notificationIndicator2.hidden = NO;
    self.notificationbutton2.enabled = NO;

    NSLog(@"Set a notification two minutes before deadline: %@", self.notification);
    }
}

-(void)notificationbutton3Selected:(id)sender
{
    // Establish the correct time interval
    NSTimeInterval timeInterval = self.timeInterval - (5 * 60);

    // Make sure there is enough time left on the clock to set the alert.
    if (timeInterval < 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"Not enough time left on the timer to set that alert" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];    }
    else {

        NSTimeInterval timeInterval = self.timeInterval - (5 * 60);
        NSDate *twoMinToDeadline = [self.initialTime dateByAddingTimeInterval:timeInterval];
        self.notification.fireDate = twoMinToDeadline;
        self.notification.alertBody = @"Five minutes to timer expiration";
        self.notification.soundName = UILocalNotificationDefaultSoundName;
        self.notification.timeZone = [NSTimeZone defaultTimeZone];
        NSLog(@"Five minute notification button selected: %@", self.notification);
        [[UIApplication sharedApplication] scheduleLocalNotification:self.notification];

        self.notificationInformationLabel.text = @"Alert set for five minutes before expiration";

        // Display the indicator check mark
        self.notificationIndicator3.hidden = NO;
        self.notificationbutton3.enabled = NO;

        NSLog(@"Set a notification five minutes before deadline: %@", self.notification);
    }
}

-(void)notificationbutton4Selected:(id)sender
{
    // Establish the correct time interval
    NSTimeInterval timeInterval = self.timeInterval - (10 * 60);

    // Make sure there is enough time left on the clock to set the alert.
    if (timeInterval < 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"Not enough time left on the timer to set that alert" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];    }
    else {
        NSTimeInterval timeInterval = self.timeInterval - (10 * 60);
        NSDate *twoMinToDeadline = [self.initialTime dateByAddingTimeInterval:timeInterval];
        self.notification.fireDate = twoMinToDeadline;
        self.notification.alertBody = @"Ten minutes to timer expiration";
        self.notification.soundName = UILocalNotificationDefaultSoundName;
        self.notification.timeZone = [NSTimeZone defaultTimeZone];
        NSLog(@"Ten minute notification button selected: %@", self.notification);
        [[UIApplication sharedApplication] scheduleLocalNotification:self.notification];

        self.notificationInformationLabel.text = @"Alert set for ten minutes before expiration";

        // Display the indicator check mark
        self.notificationIndicator4.hidden = NO;
        self.notificationbutton4.enabled = NO;

        NSLog(@"Set a notification ten minutes before deadline: %@", self.notification);
    }
}

-(void)cancelNotificationButtonSelected:(id)sender
{
    // Cancel notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];

    // Hide the indicator views
    [self hideIndicatorViews];

    // Enable notificaiton buttons if time is still on the clock, disable if not.
    if (self.timeInterval > 0) {
        [self enableNotificationButtons];
    }
    else {
        [self disableNotificationButtons];
    }

    // Reset notification label text.
    _notificationInformationLabel.text = @"Set an alert prior to timer expiration";
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
        // Disable notification buttons, cancel any outstanding notifications.
        [self disableNotificationButtons];
        [self hideIndicatorViews];
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        self.notificationInformationLabel.text = @"Set an alert prior to timer expiration";

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

-(void)disableNotificationButtons
{
    for (UIButton *button in self.buttonsArray2) {
        button.enabled = NO;
    }
}

-(void)enableNotificationButtons
{
    for (UIButton *button in self.buttonsArray2) {
        button.enabled = YES;
    }
}

-(void)hideIndicatorViews;
{
    self.notificationIndicator1.hidden = YES;
    self.notificationIndicator2.hidden = YES;
    self.notificationIndicator3.hidden = YES;
    self.notificationIndicator4.hidden = YES;
}


@end
