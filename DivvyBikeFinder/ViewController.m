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
#import "BikeTableViewCell.h"
#import <AddressBookUI/AddressBookUI.h>
#import "NoDocksAnnotation.h"
#import "DivvyBikeAnnotation.h"
#import "NoBikesAnnotation.h"

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSTimer *timer;
@property CLLocationManager *locationManager;
@property CLLocation *userLocation;
@property NSArray *divvyStations;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *locationButtonOutlet;
@property (weak, nonatomic) IBOutlet UISearchBar *fromSearchField;
@property (weak, nonatomic) IBOutlet UISearchBar *destinationSearchField;
@property NSString *userLocationString;
@property NSString *userDestinationString;
@property (weak, nonatomic) IBOutlet UIButton *currentLocationButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *searchButtonOutlet;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setStyle];

    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager startUpdatingLocation];
    self.locationManager.delegate = self;
    [self createTimer];
}

#pragma mark - Location manager methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000) {
            [self.locationManager stopUpdatingLocation];
            self.userLocation = location;
            [self getUserLocationString];
            CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude);
            MKCoordinateSpan span = MKCoordinateSpanMake(.03, .03);
            MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
            [self.mapView setRegion:region animated:YES];
            [self getJSON];
            break;
        }
    }
}

#pragma  mark - IBActions

- (IBAction)onRefreshButtonPressed:(id)sender
{
    [self createTimer];
    [self.locationManager startUpdatingLocation];
}
- (IBAction)onUseCurrentLocationPressed:(id)sender
{
    self.fromSearchField.text = self.userLocationString;
}
- (IBAction)onSearchButtonPressed:(id)sender
{
    self.userDestinationString = self.destinationSearchField.text;
    [self.destinationSearchField endEditing:YES];

}

#pragma  mark - Helper methods

-(void)getJSON
{
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
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
                 divvyStation.coordinate = CLLocationCoordinate2DMake(divvyStation.latitude.floatValue, divvyStation.longitude.floatValue);

                 CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:divvyStation.latitude.floatValue longitude:divvyStation.longitude.floatValue];
                 divvyStation.distanceFromUser = [stationLocation distanceFromLocation:self.userLocation];


                 if (divvyStation.availableBikes.intValue < 1) {
                     NoBikesAnnotation *noBikesPin = [[NoBikesAnnotation alloc] init];
                     noBikesPin.coordinate = divvyStation.coordinate;
                     NSLog(@"no bikes");
                     [self.mapView addAnnotation:noBikesPin];
                 }
                 else if (divvyStation.availableDocks.intValue < 1) {
                     NoDocksAnnotation *noDocksPin = [[NoDocksAnnotation alloc] init];
                     noDocksPin.coordinate = divvyStation.coordinate;
                     NSLog(@"no docks");
                     [self.mapView addAnnotation:noDocksPin];
                 }

                 else {
                     DivvyBikeAnnotation *divvyBikesPin = [[DivvyBikeAnnotation alloc] init];
                     divvyBikesPin.coordinate = divvyStation.coordinate;
                     NSLog(@"no bikes");
                     [self.mapView addAnnotation:divvyBikesPin];
                 }

                 [tempArray addObject:divvyStation];
             }

//
//                 self.stationAnnotation = [[MKPointAnnotation alloc] init];
//                 self.stationAnnotation.coordinate = divvyStation.coordinate;
//                 self.stationAnnotation.title = divvyStation.stationName;
//                 self.stationAnnotation.subtitle = [NSString stringWithFormat:@"Bikes: %@     Docks: %@", divvyStation.availableBikes, divvyStation.availableDocks];
//                    [self.mapView addAnnotation:self.stationAnnotation];
//
//
//        }
             NSLog(@"I ran");
        NSSortDescriptor *distanceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
        NSArray *sortDescriptors = @[distanceDescriptor];
        NSArray *divvyStationsArray = [NSArray arrayWithArray:tempArray];
        self.divvyStations = [divvyStationsArray sortedArrayUsingDescriptors:sortDescriptors];
        [self.tableView reloadData];
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[NoBikesAnnotation class]])
    {
                MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
                pin.canShowCallout = YES;
                pin.image = [UIImage imageNamed:@"nobikes"];
                NSLog(@"no bikes");
                return pin;
        }
    else if ([annotation isKindOfClass:[NoDocksAnnotation class]]) {
                MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
                pin.canShowCallout = YES;
                pin.image = [UIImage imageNamed:@"dock"];
                NSLog(@"no docks");
                return pin;
        }
    else if ([annotation isKindOfClass:[DivvyBikeAnnotation class]])
        {
            MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
            pin.canShowCallout = YES;
            pin.image = [UIImage imageNamed:@"Divvy-FB"];
            return pin;
        }
    return nil;
}

- (void)getUserLocationString
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    [geocoder reverseGeocodeLocation:self.userLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark *placemark in placemarks) {
            self.userLocationString = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
            NSLog(@"%@", self.userLocationString);
        }
    }];
}

-(void)getDestination
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    [geocoder geocodeAddressString:self.userDestinationString completionHandler:^(NSArray *placemarks, NSError *error) {

        for (CLPlacemark *placemark in placemarks) {
            MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
            annotation.title = placemark.name;
            annotation.coordinate = placemark.location.coordinate;
            [self.mapView addAnnotation:annotation];

            [self.mapView setCenterCoordinate:placemark.location.coordinate animated:YES];
            CLLocationCoordinate2D centerCoordinate = placemark.location.coordinate;
            MKCoordinateSpan span = MKCoordinateSpanMake(0.075, 0.075);
            MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
            [self.mapView setRegion:region animated:YES];
        }
    }];
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

#pragma mark - Tableview methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.divvyStations.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DivvyStation *divvyStation = [self.divvyStations objectAtIndex:indexPath.row];
    BikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.backgroundColor = [UIColor blackColor];

    cell.stationLabel.text = divvyStation.stationName;
    cell.stationLabel.textColor = [UIColor whiteColor];

    cell.bikesLabel.text = [NSString stringWithFormat:@"Bikes\n%@", divvyStation.availableBikes.description];
    cell.bikesLabel.textColor = [UIColor whiteColor];

    cell.docksLabel.text = [NSString stringWithFormat:@"Docks\n%@", divvyStation.availableDocks.description];
    cell.docksLabel.textColor = [UIColor whiteColor];

    NSString *milesFromUser = [NSString stringWithFormat:@"%.02f miles", divvyStation.distanceFromUser * 0.000621371];
    cell.distanceLabel.text = milesFromUser;


    if (divvyStation.availableBikes.floatValue < 1) {
        cell.bikesLabel.textColor = [UIColor redColor];
    }
    else
    {
        cell.bikesLabel.textColor = [UIColor whiteColor];
    }
    if (divvyStation.availableDocks.floatValue < 1) {
        cell.docksLabel.textColor = [UIColor redColor];
    }
    else
    {
        cell.docksLabel.textColor = [UIColor whiteColor];
    }
    return cell;
}

#pragma  mark - Toggle logic methods
- (void)segmentChanged:(id)sender
{
    if ([sender selectedSegmentIndex] == 0) {
        self.mapView.hidden = NO;
        self.currentLocationButtonOutlet.hidden = NO;
        self.tableView.hidden = YES;
    }
    else
    {
        self.currentLocationButtonOutlet.hidden = YES;
        self.mapView.hidden = YES;
        self.tableView.hidden = NO;
    }
}
- (IBAction)onSegmentControlToggle:(id)sender
{
    [self segmentChanged:sender];
}

-(void)setStyle
{
    // Set hidden/show initial views
    self.mapView.hidden = NO;
    self.tableView.hidden = YES;

    //Set backgroundview
    self.view.backgroundColor = [UIColor blackColor];

    self.navigationItem.title = @"Divvy Bike Finder";

    //Current location button
    self.currentLocationButtonOutlet.layer.cornerRadius = 5.0f;
    self.currentLocationButtonOutlet.layer.borderWidth = 1.0f;
    self.currentLocationButtonOutlet.layer.borderColor = [[UIColor blueColor] CGColor];

    //"Go" button
    self.searchButtonOutlet.layer.cornerRadius = 5.0f;
    self.searchButtonOutlet.layer.borderWidth = 1.0f;
    self.searchButtonOutlet.layer.borderColor = [[UIColor blueColor] CGColor];

    self.locationButtonOutlet.titleLabel.numberOfLines = 2;

    //Segmented control
    self.segmentedControl.backgroundColor = [UIColor blueColor];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    self.segmentedControl.layer.borderColor = [[UIColor blueColor] CGColor];
    self.segmentedControl.layer.borderWidth = 1.0f;
    self.segmentedControl.layer.cornerRadius = 5.0f;
    self.segmentedControl.alpha = .8f;

    //"From" search bar
    [self.fromSearchField setBackgroundImage:[UIImage new]];
    [self.fromSearchField setTranslucent:YES];

    //Destination search bar
    [self.destinationSearchField setBackgroundImage:[UIImage new]];
    [self.destinationSearchField setTranslucent:YES];
}



@end
