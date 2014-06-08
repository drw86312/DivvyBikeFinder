//
//  ViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 6/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "ViewController.h"
#import "DivvyStation.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSTimer *timer;
@property CLLocationManager *locationManager;
@property CLLocation *userLocation;

@end

@implementation ViewController

- (void)viewDidLoad
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    [super viewDidLoad];
    [self getJSON];
    [self createTimer];
}

#pragma mark - Location manager methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000) {
            [self.locationManager stopUpdatingLocation];
            CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
            MKCoordinateSpan span = MKCoordinateSpanMake(0.03, 0.03);
            MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
            self.userLocation = location;
            [self.mapView setRegion:region animated:YES];
            break;
        }
        else
        {
            CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(41.89, -87.66);
            MKCoordinateSpan span = MKCoordinateSpanMake(0.15, 0.23);
            MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
            [self.mapView setRegion:region animated:YES];
        }
    }
}

#pragma  mark - IBActions

- (IBAction)onRefreshButtonPressed:(id)sender
{
    [self getJSON];
    [self createTimer];
}

#pragma  mark - Helper methods

-(void)getJSON
{
    NSString *urlString = @"http://www.divvybikes.com/stations/json";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
         {
             NSDictionary *dictionary  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&connectionError];

             NSArray *stationsArray = [dictionary objectForKey:@"stationBeanList"];

             for (NSDictionary *dictionary in stationsArray) {

                 DivvyStation *divvyStation = [[DivvyStation alloc] init];

                 divvyStation.stationName = [dictionary objectForKey:@"stationName"];
                 divvyStation.statusValue = [dictionary objectForKey:@"statusValue"];
                 divvyStation.streetAddress1 = [dictionary objectForKey:@"stAddress1"];
                 divvyStation.streetAddress2 = [dictionary objectForKey:@"stAddress2"];
                 divvyStation.city = [dictionary objectForKey:@"city"];
                 divvyStation.postalCode = [dictionary objectForKey:@"postalCode"];
                 divvyStation.location = [dictionary objectForKey:@"location"];
                 divvyStation.landMark = [dictionary objectForKey:@"landMark"];

                 float longitude = [[dictionary objectForKey:@"longitude"] floatValue];
                 divvyStation.longitude = [NSNumber numberWithFloat:longitude];
                 float latitude = [[dictionary objectForKey:@"latitude"] floatValue];
                 divvyStation.latitude = [NSNumber numberWithFloat:latitude];
                 int docks = [[dictionary objectForKey:@"availableDocks"] intValue];
                 divvyStation.availableDocks = [NSNumber numberWithInt:docks];
                 int bikes = [[dictionary objectForKey:@"availableBikes"] intValue];
                 divvyStation.availableBikes = [NSNumber numberWithInt:bikes];
                 int totaldocks = [[dictionary objectForKey:@"totalDocks"] intValue];
                 divvyStation.totalDocks = [NSNumber numberWithInt:totaldocks];
                 int key = [[dictionary objectForKey:@"statusKey"] intValue];
                 divvyStation.statusKey = [NSNumber numberWithInt:key];
                 int identifier = [[dictionary objectForKey:@"id"] intValue];
                 divvyStation.identifier = [NSNumber numberWithInt:identifier];

                 self.stationAnnotation = [[MKPointAnnotation alloc] init];
                 self.stationAnnotation.coordinate = CLLocationCoordinate2DMake(divvyStation.latitude.floatValue, divvyStation.longitude.floatValue);
                 self.stationAnnotation.title = divvyStation.stationName;
                 self.stationAnnotation.subtitle = [NSString stringWithFormat:@"Bikes: %@     Docks: %@", divvyStation.availableBikes, divvyStation.availableDocks];

                 [self.mapView addAnnotation:self.stationAnnotation];
             }
         }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];

    pin.image = [UIImage imageNamed:@"Divvy-FB"];
    pin.canShowCallout = YES;

    return pin;
}

#pragma mark - Timer methods

-(void)createTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
}

-(void)timer:(NSTimer *)timer
{
    [self getJSON];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}






@end
