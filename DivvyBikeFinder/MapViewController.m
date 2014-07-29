//
//  MapViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 6/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "MapViewController.h"
#import "DivvyStation.h"
#import <QuartzCore/QuartzCore.h>
#import "BikeTableViewCell.h"
#import <AddressBookUI/AddressBookUI.h>
#import "NoDocksAnnotation.h"
#import "DivvyBikeAnnotation.h"
#import "NoBikesAnnotation.h"
#import "StationDetailViewController.h"
#import "SearchViewController.h"
#import "UIColor+DesignColors.h"

@interface MapViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSTimer *timer;
@property CLLocationManager *locationManager;
@property CLLocation *userLocation;
@property NSArray *divvyStations;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSString *userLocationString;
@property NSString *userDestinationString;
@property UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchButtonOutlet;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButtonOutlet;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create the activity indicator
    CGFloat indicatorWidth = 50.0f;
    CGFloat indicatorHeight = 50.0f;

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.frame = CGRectMake((self.view.frame.size.width/2) - (indicatorWidth/2), (self.view.frame.size.height/2) - (indicatorHeight/2), indicatorWidth, indicatorHeight);
    self.activityIndicator.hidden = YES;
    [self.view addSubview:self.activityIndicator];

    // Don't enable these buttons until, Divvy API call has completed.
    self.searchButtonOutlet.enabled = NO;
    self.refreshButtonOutlet.enabled = NO;

    [self setStyle];

    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager startUpdatingLocation];
    self.locationManager.delegate = self;
}

#pragma mark - Location manager methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000) {
            [self.locationManager stopUpdatingLocation];
            self.userLocation = location;
            CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude);
            MKCoordinateSpan span = MKCoordinateSpanMake(.025, .025);
            MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
            self.mapView.showsUserLocation = YES;
            [self.mapView setRegion:region animated:YES];
            [self getJSON];
            break;
        }
    }
}

#pragma  mark - IBActions

- (IBAction)onRefreshButtonPressed:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.locationManager startUpdatingLocation];
}


#pragma  mark - Helper methods

-(void)getJSON
{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    NSString *urlString = @"http://www.divvybikes.com/stations/json";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         if (connectionError) {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Connect to Divvy" message:@"Try again later" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
             [alert show];
             self.refreshButtonOutlet.enabled = YES;
         }

         else {

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
                 [self.mapView addAnnotation:noBikesPin];
             }
             else if (divvyStation.availableDocks.intValue < 1) {
                 NoDocksAnnotation *noDocksPin = [[NoDocksAnnotation alloc] init];
                 noDocksPin.coordinate = divvyStation.coordinate;
                 [self.mapView addAnnotation:noDocksPin];
             }

             else {
                 DivvyBikeAnnotation *divvyBikesPin = [[DivvyBikeAnnotation alloc] init];
                 divvyBikesPin.coordinate = divvyStation.coordinate;
                 [self.mapView addAnnotation:divvyBikesPin];
             }

             [tempArray addObject:divvyStation];
         }

         NSSortDescriptor *distanceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
         NSArray *sortDescriptors = @[distanceDescriptor];
         NSArray *divvyStationsArray = [NSArray arrayWithArray:tempArray];
         self.divvyStations = [divvyStationsArray sortedArrayUsingDescriptors:sortDescriptors];
         [self.tableView reloadData];
        }
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
    self.searchButtonOutlet.enabled = YES;
    self.refreshButtonOutlet.enabled = YES;
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:MKUserLocation.class]) {
        return nil;
    }
    else if ([annotation isKindOfClass:[NoBikesAnnotation class]])
    {
        MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        pin.canShowCallout = YES;
        pin.image = [UIImage imageNamed:@"nobikes"];
        return pin;
    }
    else if ([annotation isKindOfClass:[NoDocksAnnotation class]]) {
        MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        pin.canShowCallout = YES;
        pin.image = [UIImage imageNamed:@"dock"];
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



#pragma mark - Timer methods


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

        cell.backgroundColor = [UIColor divvyColor];

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
            else {
                cell.bikesLabel.textColor = [UIColor whiteColor];
            }
            if (divvyStation.availableDocks.floatValue < 1) {
                cell.docksLabel.textColor = [UIColor redColor];
            }
            else {
            cell.docksLabel.textColor = [UIColor whiteColor];
            }
        return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    DivvyStation *station = [self.divvyStations objectAtIndex:selectedIndexPath.row];
    StationDetailViewController *detailViewController = segue.destinationViewController;
    detailViewController.stationFromSourceVC = station;
    detailViewController.userLocationFromSourceVC = self.userLocation;
    detailViewController.userLocationStringFromSource = self.userLocationString;
}

#pragma  mark - Toggle logic methods
- (void)segmentChanged:(id)sender
{
    if ([sender selectedSegmentIndex] == 0) {
        self.mapView.hidden = NO;
        self.tableView.hidden = YES;
    }
    else
    {
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
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"Divvy & Conquer";

    //Segmented control
    self.segmentedControl.backgroundColor = [UIColor divvyColor];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    self.segmentedControl.layer.borderColor = [[UIColor divvyColor] CGColor];
    self.segmentedControl.layer.borderWidth = 1.0f;
    self.segmentedControl.layer.cornerRadius = 5.0f;
    self.segmentedControl.alpha = .8f;

    // Activity indicator
    self.activityIndicator.color = [UIColor divvyColor];

    // Search button
    self.searchButtonOutlet.tintColor = [UIColor divvyColor];

    // Refresh button
    self.refreshButtonOutlet.tintColor = [UIColor divvyColor];

    //Tab bar
    [self.tabBarController.tabBar setSelectedImageTintColor:[UIColor divvyColor]];
}

@end
