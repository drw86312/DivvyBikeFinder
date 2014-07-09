//
//  StationDetailViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 7/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "StationDetailViewController.h"
#import <MapKit/MapKit.h>

@interface StationDetailViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property CLLocationManager *locationManager;
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
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x + 10, self.view.frame.origin.x + 75, self.view.frame.size.width - 20, 125)];
    backgroundView.layer.borderWidth = 1.0f;
    backgroundView.layer.borderColor = [[UIColor redColor] CGColor];
    backgroundView.layer.cornerRadius = 5.0f;
    [self.view addSubview:backgroundView];
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



@end
