//
//  StationDetailViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 7/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "StationDetailViewController.h"
#import "UIColor+DesignColors.h"
#import <MapKit/MapKit.h>

@interface StationDetailViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property CLLocationManager *locationManager;
@property UIView *backgroundView;
@property NSMutableArray *buttonsArray;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation StationDetailViewController



- (void)viewDidLoad
{
    [super viewDidLoad];

    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager startUpdatingLocation];
    self.locationManager.delegate = self;
    [self makeStationDetailView];
}

-(void)makeStationDetailView
{
    // Find status and navigation bar heights
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;

    CGFloat backgroundViewHeight = 120.0f;
    CGFloat verticalOffset = 5.0f;
    CGFloat horizontalOffset = 5.0f;


    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x + 10, navBarHeight + statusBarHeight + 5.0f, self.view.frame.size.width - 20, backgroundViewHeight)];
    self.backgroundView.layer.borderWidth = 1.0f;
    self.backgroundView.layer.borderColor = [[UIColor divvyColor] CGColor];
    self.backgroundView.layer.cornerRadius = 5.0f;
    [self.view addSubview:self.backgroundView];

    UILabel *stationLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, self.backgroundView.frame.size.width - (2 * horizontalOffset), 20.0f)];
    stationLabel.text = [NSString stringWithFormat:@"%@", self.stationFromSourceVC.stationName];
    stationLabel.textColor = [UIColor divvyColor];
    [stationLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:17]];
    [self.backgroundView addSubview:stationLabel];

    verticalOffset = verticalOffset + stationLabel.frame.size.height;

    UILabel *addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, self.backgroundView.frame.size.width - (2 * horizontalOffset), 20.0f)];
    addressLabel.text = [NSString stringWithFormat:@"%@ Chicago IL", self.stationFromSourceVC.location];
    addressLabel.textColor = [UIColor divvyColor];
    [addressLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:15]];

    NSLog(@"City: %@", self.stationFromSourceVC.city);
    [self.backgroundView addSubview:addressLabel];

    [self makeExploreButtons];
}

-(void)makeExploreButtons
{
    self.buttonsArray = [NSMutableArray new];

    UIButton *button1 = [[UIButton alloc] init];
    UIButton *button2 = [[UIButton alloc] init];
    UIButton *button3 = [[UIButton alloc] init];
    UIButton *button4 = [[UIButton alloc] init];
    UIButton *button5 = [[UIButton alloc] init];

    [self.buttonsArray addObject:button1];
    [self.buttonsArray addObject:button2];
    [self.buttonsArray addObject:button3];
    [self.buttonsArray addObject:button4];
    [self.buttonsArray addObject:button5];

    CGFloat spacing = 5.0f;
    CGFloat verticalOffset = self.backgroundView.frame.origin.y + self.backgroundView.frame.size.height + spacing;
    CGFloat horizontalOffset = 10.0f;
    CGFloat buttonWidth = (self.backgroundView.frame.size.width - ((self.buttonsArray.count - 1) * spacing))/ self.buttonsArray.count;
    CGFloat buttonHeight = buttonWidth;

    for (UIButton *button in self.buttonsArray) {
        button.frame = CGRectMake(horizontalOffset, verticalOffset, buttonWidth, buttonHeight);
        button.layer.cornerRadius = 5.0f;
        button.backgroundColor = [UIColor divvyColor];
        button.titleLabel.textColor = [UIColor whiteColor];
        [button setTintColor:[UIColor divvyColor]];
        button.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        horizontalOffset += button.frame.size.width + spacing;
        [self.view addSubview:button];
    }

    [button1 setTitle:@"Eat" forState:UIControlStateNormal];
    [button2 setTitle:@"Drink" forState:UIControlStateNormal];
    [button3 setTitle:@"Shop" forState:UIControlStateNormal];
    [button4 setTitle:@"Sightsee" forState:UIControlStateNormal];
    [button5 setTitle:@"Transit" forState:UIControlStateNormal];

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

    [button5 addTarget:self
                action:@selector(button5Selected:)
      forControlEvents:UIControlEventTouchUpInside];

}

-(void)button1Selected:(id)sender
{
    NSLog(@"Food button selected");
    [self disableButtons];
}

-(void)button2Selected:(id)sender
{
    NSLog(@"Drink button selected");
    [self disableButtons];
}

-(void)button3Selected:(id)sender
{
    NSLog(@"Shop button selected");
    [self disableButtons];
}

-(void)button4Selected:(id)sender
{
    NSLog(@"Sightsee button selected");
    [self disableButtons];
}

-(void)button5Selected:(id)sender
{
    NSLog(@"Transit button selected");
    [self disableButtons];
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000) {
            [self.locationManager stopUpdatingLocation];
            self.userLocationFromSourceVC = location;
            CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(self.userLocationFromSourceVC.coordinate.latitude, self.userLocationFromSourceVC.coordinate.longitude);
            MKCoordinateSpan span = MKCoordinateSpanMake(.005, .005);
            MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
            self.mapView.showsUserLocation = YES;
            [self.mapView setRegion:region animated:YES];
            break;
        }
    }
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


@end
