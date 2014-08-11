//
//  SearchViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 7/23/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "SearchViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "DivvyStation.h"
#import "DivvyBikeAnnotation.h"
#import "BikeTableViewCell.h"
#import "TripTableViewCell.h"
#import "RouteTableViewCell.h"
#import "DestinationAnnotation.h"
#import "UIColor+DesignColors.h"
#import "UIFont+DesignFonts.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "StationDetailViewController.h"
#import "RouteDetailsViewController.h"

@interface SearchViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property CLLocation *userLocation;
@property CLLocation *chicago;
@property CLLocationManager *locationManager;
@property MKPlacemark *originPlacemark;
@property MKPlacemark *destinationPlacemark;
@property NSArray *divvyStations;
@property NSArray *stationsNearOrigin;
@property NSArray *stationsNearDestination;
@property NSMutableArray *routeDictionaries;
@property NSString *userLocationString;
@property NSString *userDestinationString;
@property NSString *walkRoute1DistanceString;
@property NSString *bikeRouteDistanceString;
@property NSString *walkRoute2DistanceString;
@property NSString *totalDistanceString;
@property NSString *travelTimeString;
@property MKRoute *bikeRoute;
@property MKRoute *walkRoute1;
@property MKRoute *walkroute2;
@property DivvyStation *selectedStation;
@property UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *currentLocationButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *cancelButtonOutlet;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *fromTextFieldOutlet;
@property (weak, nonatomic) IBOutlet UITextField *destinationTextFieldOutlet;
@property (weak, nonatomic) IBOutlet UIView *tableViewBlockerView;
@property UIView *mapContainerView;
@property BOOL firstSearch;
@property CGFloat distanceCounter;
@property CGFloat etaCounter;
@property NSInteger toggleIndex;
@property NSDictionary *selectedRouteDictionary;

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Disable UI, enable when JSON has returned.
    [self disableUI];

    // Create the activity indicator
    CGFloat indicatorWidth = 50.0f;
    CGFloat indicatorHeight = 50.0f;

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.frame = CGRectMake((self.view.frame.size.width/2) - (indicatorWidth/2), (self.view.frame.size.height/2) - (indicatorHeight/2), indicatorWidth, indicatorHeight);
    [self.view addSubview:self.activityIndicator];

    // Instantiate a location for the city of Chicago (used for handling cases when users are not in Chicago)
    self.chicago = [[CLLocation alloc] initWithLatitude:41.891813 longitude:-87.647343];

    // Set delegates
    self.destinationTextFieldOutlet.delegate = self;
    self.fromTextFieldOutlet.delegate = self;

    // Set correct views to show or be hidden.
    self.mapView.hidden = NO;
    self.tableView.hidden = YES;
    self.segmentedControl.enabled = NO;
    self.toggleIndex = 0;

    // Helper method for styling views
    [self setStyle];

    // Get DivvyBike Data
    [self getJSON];
}

#pragma mark - Location manager methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 700 && location.horizontalAccuracy < 700) {
            [self.locationManager stopUpdatingLocation];

            // Assign userlocation IVar
            self.userLocation = location;

            // If there is a user location assign the distance from user property
            if (self.userLocation) {
                NSLog(@"User location found");
                for (DivvyStation *divvyStation in self.divvyStations) {
                    // Assign the distance from user property, if there is a user location.
                    CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:divvyStation.latitude.floatValue longitude:divvyStation.longitude.floatValue];
                    divvyStation.distanceFromUser = [stationLocation distanceFromLocation:self.userLocation];
                }
                // Sort stations array by distance from user
                NSArray *tempArray = [NSArray arrayWithArray:self.divvyStations];
                NSSortDescriptor *distanceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
                NSArray *sortDescriptors = @[distanceDescriptor];
                NSArray *divvyStationsArray = [NSArray arrayWithArray:tempArray];
                self.divvyStations = [divvyStationsArray sortedArrayUsingDescriptors:sortDescriptors];

                // Instantiate chicago location and assign the "distance from chicago" variable
                CLLocation *chicago = [[CLLocation alloc] initWithLatitude:41.891813 longitude:-87.647343];
                CGFloat userDistanceFromChicago = [chicago distanceFromLocation:self.userLocation];
                self.mapView.showsUserLocation = YES;

                // If user is too far from Chicago, map will default to the Chicago area.
                // 80,466 meters is 50 miles, approximately.
                if (userDistanceFromChicago > 80466) {
                    NSLog(@"User is not in Chicago");
                    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(chicago.coordinate.latitude, chicago.coordinate.longitude);
                    MKCoordinateSpan span = MKCoordinateSpanMake(.1, .1);
                    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
                    [self.mapView setRegion:region animated:YES];
                }
                // If user is in Chicago, draw map around their location.
                else {
                    NSLog(@"User is in Chicago");
                    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude);
                    MKCoordinateSpan span = MKCoordinateSpanMake(.03, .03);
                    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
                    [self.mapView setRegion:region animated:YES];
                }
            }
            // Else, no user locations returned.
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention" message:@"Let Divvy & Conquer use your current location for best performance" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
        }
        // Else, user location found, but not with sufficient accuracy...
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention" message:@"Let Divvy & Conquer use your current location for best performance" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    // Enable UI and dismiss activity indicator.
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
    [self enableUI];
    NSLog(@"Enabling UI");
    }
}

-(void)getJSON
{
    NSLog(@"Getting JSON");
    // Start the activity indicator spinning while waiting for API call to return data.
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];

    // Create a temporary array to hold divvyStation objects
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];

    // Formulate Divvy API request
    NSString *urlString = @"http://www.divvybikes.com/stations/json";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         // Check for connection error..
         if (connectionError) {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Connect to Divvy" message:@"Try again later" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
             [alert show];
             [self enableUI];
             self.activityIndicator.hidden = YES;
             [self.activityIndicator stopAnimating];
         }

         // If no connection error
         else {

             // Serialize the returned JSON and assign properties to divvyStation objects
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
                 divvyStation.annotationSize = 20.0f + (0.5f * (divvyStation.availableBikes.floatValue + divvyStation.availableDocks.floatValue));

                 // Add the divvyStation to the temporary array.
                 [tempArray addObject:divvyStation];
             }

             // Assign the temp array to the iVar
             self.divvyStations = [NSArray arrayWithArray:tempArray];
             [self setStationColors:self.divvyStations];

             // Find user location..
             self.locationManager = [[CLLocationManager alloc] init];
             self.locationManager.delegate = self;
             [self.locationManager startUpdatingLocation];
         }
     }];
}

#pragma mark - IBActions

- (IBAction)onCancelButtonPressed:(id)sender
{
    self.userDestinationString = nil;
    self.fromTextFieldOutlet.text = nil;
    self.destinationTextFieldOutlet.text = nil;
    [self.fromTextFieldOutlet endEditing:YES];
    [self.destinationTextFieldOutlet endEditing:YES];
}

- (IBAction)onCurrentLocationButtonPressed:(id)sender
{
    [self disableUI];
    // Show activity indicator
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    // Get user location string
    [self getUserLocationString];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    // Check to make sure there are DivvyStations
    if (self.divvyStations) {

        // Check to make sure the search fields aren't empty
        if (self.fromTextFieldOutlet) {
            self.userLocationString = self.fromTextFieldOutlet.text;
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please insert a starting location" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }

        if (self.destinationTextFieldOutlet) {
            self.userDestinationString = self.destinationTextFieldOutlet.text;
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please insert a destination" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }

        // If search fields aren't empty...
        if (self.fromTextFieldOutlet && self.destinationTextFieldOutlet) {
            // Disable user interaction
            [self disableUI];

            // Clear map of annotations and route overlays
            [self.mapView removeAnnotations:self.mapView.annotations];
            // Remove old route overlays from mapview.
            if (self.walkRoute1) {
                [self.mapView removeOverlay:self.walkRoute1.polyline];
            }

            if (self.bikeRoute) {
                [self.mapView removeOverlay:self.bikeRoute.polyline];
            }

            if (self.walkroute2) {
                [self.mapView removeOverlay:self.walkroute2.polyline];
            }

            // Reveal the segmented control, so users can see route details.
            self.segmentedControl.enabled = YES;

            // Dismiss keyboard
            [self.destinationTextFieldOutlet endEditing:YES];
            [self.fromTextFieldOutlet endEditing:YES];

            // Clear search fields' text.
            self.destinationTextFieldOutlet.text = nil;
            self.fromTextFieldOutlet.text = nil;

            // Show activity indicator
            self.activityIndicator.hidden = NO;
            [self.activityIndicator startAnimating];

            // Remove map labels
            [self.mapContainerView removeFromSuperview];

            // Begin search process
            self.firstSearch = YES;
            [self getOriginFromName];
            }
        }
    // No DivvyStations..
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry, Divvy data not available" message:@"Please try again later" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    return YES;
}

#pragma mark - Search-related methods

-(void)getOriginFromName
{
    NSLog(@"Origin Search term: %@", self.userLocationString);
    NSLog(@"Destination Search term: %@", self.userDestinationString);

    // Search for a placemark for the origin location.
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = self.userLocationString;
    request.region = MKCoordinateRegionMake(self.userLocation.coordinate, MKCoordinateSpanMake(.3, .3));
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];

    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        NSArray *mapItems = response.mapItems;
        if (mapItems.count > 0) {
            MKMapItem *mapItem = [mapItems firstObject];
            self.originPlacemark = mapItem.placemark;
            NSLog(@"Origin found %@", self.originPlacemark.name);
            [self getDestinationFromName];
        }
        else {
            // If name search is unsuccessful, try geocoding the user location string as an address.
            [self getOriginFromAddress];
        }
    }];
}

-(void)getOriginFromAddress
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:self.userLocationString completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count > 0) {
            self.originPlacemark = [placemarks firstObject];
            NSLog(@"Origin found %@", self.originPlacemark.name);
            [self getDestinationFromName];
            }
        else {
            if (self.firstSearch) {
                NSLog(@"Running origin search with 'chicago' added");
                self.userLocationString = [self.userLocationString stringByAppendingString:@" Chicago"];
                self.userDestinationString = [self.userDestinationString stringByAppendingString:@" Chicago"];
                self.firstSearch = NO;
                [self getOriginFromName];
            }
            else {
                // Show alert that origin result was not found.
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Sorry, no results found matching %@", self.userLocationString] message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                self.activityIndicator.hidden = YES;
                [self.activityIndicator stopAnimating];
                [self enableUI];
            }
        }
    }];
}

// Should run after an origin placemark has been found. Same process as with the origin string.
-(void)getDestinationFromName
{
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = self.userDestinationString;
    request.region = MKCoordinateRegionMake(self.userLocation.coordinate, MKCoordinateSpanMake(.3, .3));
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];

    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        NSArray *mapItems = response.mapItems;
        if (mapItems.count > 0) {
            MKMapItem *mapItem = [mapItems firstObject];
            self.destinationPlacemark = mapItem.placemark;
            NSLog(@"Destination found %@", self.destinationPlacemark.name);
            [self checkThatOriginDestinationInChicago];
        }
        else {
            [self getDestinationFromAddress];
        }
    }];
}

-(void)getDestinationFromAddress
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    [geocoder geocodeAddressString:self.userDestinationString completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count > 0) {
            self.destinationPlacemark = [placemarks firstObject];
            [self checkThatOriginDestinationInChicago];
            NSLog(@"Destination found %@", self.destinationPlacemark.name);
        }
        else {
            if (self.firstSearch) {
                NSLog(@"Running destination search with 'chicago' added");
                self.userLocationString = [self.userLocationString stringByAppendingString:@" Chicago"];
                self.userDestinationString = [self.userDestinationString stringByAppendingString:@" Chicago"];
                self.firstSearch = NO;
                [self getOriginFromName];
            }
            else {
                // Show alert that destination result was not found.
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Sorry, no results found matching %@", self.userDestinationString] message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                self.activityIndicator.hidden = YES;
                [self.activityIndicator stopAnimating];
                [self enableUI];
            }
        }
    }];
}

// If origin and destination placemarks are found, create pin annotations.
-(void)checkThatOriginDestinationInChicago
{
    NSLog(@"Performing check that placemarks are in Chicago");

    // If both origin and destinations have been found...
    if (self.destinationPlacemark && self.originPlacemark) {

        NSLog(@"Destination placemark: %@", self.destinationPlacemark.description);

        // Create CLLoction objects for origin and destination placemarks
        CLLocation *originLocation = [[CLLocation alloc] initWithLatitude:self.originPlacemark.coordinate.latitude longitude:self.originPlacemark.coordinate.longitude];
        CLLocation *destinationLocation = [[CLLocation alloc] initWithLatitude:self.destinationPlacemark.coordinate.latitude longitude:self.destinationPlacemark.coordinate.longitude];

        // Include logic that makes sure the origin and destination locations are within an acceptable area around Chicago.
        CGFloat originDistanceFromChicago = [self.chicago distanceFromLocation:originLocation];
        CGFloat destinationDistanceFromChicago = [self.chicago distanceFromLocation:destinationLocation];

        // 32,186.9 meters is 20 miles, approximately.
        if (originDistanceFromChicago > 32186.9f) {
            // Try the search with Chicago added to the userlocation string...
            if (self.firstSearch) {
                NSLog(@"Origin found outside Chicago, running search with 'chicago' added");
                self.userLocationString = [self.userLocationString stringByAppendingString:@" Chicago"];
                self.userDestinationString = [self.userDestinationString stringByAppendingString:@" Chicago"];
                self.firstSearch = NO;
                [self getOriginFromName];
            }
            else {
                // Show alert that origin result was not found.
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Sorry, no results found matching %@", self.userLocationString] message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                self.activityIndicator.hidden = YES;
                [self.activityIndicator stopAnimating];
                [self enableUI];
            }
        }
        else if (destinationDistanceFromChicago > 32186.9f) {
            // Try the search with Chicago added to the destination string...
            if (self.firstSearch) {
                NSLog(@"Destination found outside Chicago, running search with 'chicago' added");
                self.userLocationString = [self.userLocationString stringByAppendingString:@" Chicago"];
                self.userDestinationString = [self.userDestinationString stringByAppendingString:@" Chicago"];
                self.firstSearch = NO;
                [self getOriginFromName];
            }
            else {
                // Show alert that origin result was not found.
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Sorry, no results found matching %@", self.userDestinationString] message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                self.activityIndicator.hidden = YES;
                [self.activityIndicator stopAnimating];
                [self enableUI];
            }
        }
        else {
            // Reassign search strings to what the placemark returned
            self.userLocationString = self.originPlacemark.name;
            self.userDestinationString = self.destinationPlacemark.name;

            NSLog(@"Locations are in Chicago!");
            // Find nearest Divvy Station to the origin location.
            [self findDivvyStationNearestOrigin:originLocation];
        }
    }
    else {
        // Show alert that origin/destination result was not found.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry, result not found in Chicago" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
        [self enableUI];
    }
}

-(void)findDivvyStationNearestOrigin:(CLLocation *)originLocation
{
    NSLog(@"Find DivvyStations near origin ran");

    // Get an array of the divvystations that have bikes
    NSMutableArray *tempArray1 = [NSMutableArray new];
    for (DivvyStation *divvyStation in self.divvyStations) {
        if (divvyStation.availableBikes.floatValue > 0 ) {
            [tempArray1 addObject:divvyStation];
        }
    }

    NSMutableArray *tempArray2 = [NSMutableArray new];
    // For all of the stations in tempArray1, assign the distance to userlocation property
    for (DivvyStation *divvyStation in tempArray1) {
        CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:divvyStation.latitude.floatValue longitude:divvyStation.longitude.floatValue];
        divvyStation.distanceToOriginDivvyStation = [originLocation distanceFromLocation:stationLocation];
        [tempArray2 addObject:divvyStation];
    }

    // Sort temparray2 by distance from origin
    NSSortDescriptor *originDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceToOriginDivvyStation" ascending:YES];
    NSArray *originDescriptors = @[originDescriptor];
    NSArray *sortedStationsArray = [tempArray2 sortedArrayUsingDescriptors:originDescriptors];

    DivvyStation *closestStationToOrigin = [sortedStationsArray firstObject];
    self.stationsNearOrigin = [NSArray arrayWithObject:closestStationToOrigin];

    // If there is a station-near-origin, find a station near destination, else present an alert
    if (self.stationsNearOrigin.count > 0) {
        NSLog(@"Origin DivvyStation found: %@", closestStationToOrigin.stationName);
        CLLocation *destinationLocation = [[CLLocation alloc] initWithLatitude:self.destinationPlacemark.coordinate.latitude longitude:self.destinationPlacemark.coordinate.longitude];
        [self findDivvyStationsNearDestination:destinationLocation];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:[NSString stringWithFormat:@"Unable to locate a Divvy Station near %@", self.userLocationString] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void)findDivvyStationsNearDestination:(CLLocation *)destinationLocation
{
    NSLog(@"Find DivvyStations near destination ran");

    // Get an array of the divvystations that have bikes
    NSMutableArray *tempArray1 = [NSMutableArray new];
    for (DivvyStation *divvyStation in self.divvyStations) {
        if (divvyStation.availableDocks.floatValue > 0 ) {
            [tempArray1 addObject:divvyStation];
        }
    }
    NSMutableArray *tempArray2 = [NSMutableArray new];
    // For all of the stations in tempArray1, assign the distance to userlocation property
    for (DivvyStation *divvyStation in tempArray1) {
        CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:divvyStation.latitude.floatValue longitude:divvyStation.longitude.floatValue];
        divvyStation.distanceToDestinationDivvyStation = [destinationLocation distanceFromLocation:stationLocation];
        [tempArray2 addObject:divvyStation];
    }

    // Sort temparray2 by distance from destination
    NSSortDescriptor *destinationDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceToDestinationDivvyStation" ascending:YES];
    NSArray *destinationDescriptors = @[destinationDescriptor];
    NSArray *sortedStationsArray = [tempArray2 sortedArrayUsingDescriptors:destinationDescriptors];

    DivvyStation *closestStationToDestination = [sortedStationsArray firstObject];
    self.stationsNearDestination = [NSArray arrayWithObject:closestStationToDestination];

    // If there is a station-near-destination, get the directions
    if (self.stationsNearDestination.count > 0) {
        NSLog(@"Destination DivvyStation found: %@", closestStationToDestination.stationName);
        [self getDirections];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:[NSString stringWithFormat:@"Unable to locate a Divvy Station near %@", self.userDestinationString] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - Directions methods

-(void)getDirections
{
    NSLog(@"Get directions method ran");

    // Instantiate distance and ETA counters to keep track of trip distance and time.
    self.distanceCounter = 0.0f;
    self.etaCounter = 0.0f;

    // Create mapItems for origin/destination placemarks.
    MKMapItem *originMapItem = [[MKMapItem alloc] initWithPlacemark:self.originPlacemark];
    MKMapItem *destinationMapItem = [[MKMapItem alloc] initWithPlacemark:self.destinationPlacemark];

    // Create mapItems for divvyStations.
    MKPlacemark *stationNearOrigin = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake([[[self.stationsNearOrigin firstObject] latitude] floatValue], [[[self.stationsNearOrigin firstObject] longitude] floatValue]) addressDictionary:nil];
    MKPlacemark *stationNearDestination = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake([[[self.stationsNearDestination firstObject] latitude] floatValue], [[[self.stationsNearDestination firstObject] longitude] floatValue]) addressDictionary:nil];
    MKMapItem *stationNearOriginMapItem = [[MKMapItem alloc] initWithPlacemark:stationNearOrigin];
    MKMapItem *stationNearDestinationMapItem = [[MKMapItem alloc] initWithPlacemark:stationNearDestination];

    // Create first directions request and parameters (this will be the route walking from origin to nearest DivvyStation).
    MKDirectionsRequest *directionsRequest1 = [MKDirectionsRequest new];
    directionsRequest1.source = originMapItem;
    directionsRequest1.destination = stationNearOriginMapItem;
    directionsRequest1.transportType =MKDirectionsTransportTypeWalking;

    MKDirections *directions1 = [[MKDirections alloc] initWithRequest:directionsRequest1];
    [directions1 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Unable to find a route for this trip" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            self.activityIndicator.hidden = YES;
            [self.activityIndicator stopAnimating];
            [self enableUI];
        }
            else {
                NSLog(@"Route 1 found");
                NSArray *routeItems1 = response.routes;
                self.walkRoute1 = [routeItems1 firstObject];
                self.etaCounter += self.walkRoute1.expectedTravelTime;
                self.routeDictionaries = [NSMutableArray new];
                CGFloat walkRoute1Distance = 0.0f;
                    for (MKRouteStep *routeStep in self.walkRoute1.steps) {
                        walkRoute1Distance += routeStep.distance;
                        NSNumber *distance = [NSNumber numberWithFloat:routeStep.distance];
                        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:routeStep.instructions, @"instructions",
                        distance, @"distance", @"walking", @"transportType",nil];
                        [self.routeDictionaries addObject:dictionary];
                    }
                self.walkRoute1DistanceString = [NSString stringWithFormat:@"%.01f", walkRoute1Distance * 0.000621371];
                self.distanceCounter +=walkRoute1Distance;
        // Create second directions request and parameters (DivvyStation to DivvyStation).
        MKDirectionsRequest *directionsRequest2 = [MKDirectionsRequest new];
        directionsRequest2.source = stationNearOriginMapItem;
        directionsRequest2.destination = stationNearDestinationMapItem;
        directionsRequest2.transportType =MKDirectionsTransportTypeWalking;
        directionsRequest2.requestsAlternateRoutes = YES;
        MKDirections *directions2 = [[MKDirections alloc] initWithRequest:directionsRequest2];

        [directions2 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Unable to find a route for this trip" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                self.activityIndicator.hidden = YES;
                [self.activityIndicator stopAnimating];
                [self enableUI];
            }
            else {
                NSLog(@"Route 2 found");
                NSArray *routeItems2 = response.routes;
                self.bikeRoute = [routeItems2 firstObject];
                // Assumes cycling is about 3 times faster than walking (approx. biking speed assumption is between 9.0-9.5 MPH)
                self.etaCounter += (self.bikeRoute.expectedTravelTime/3);
                CGFloat bikingDistance = 0.0f;
                    for (MKRouteStep *routeStep in self.bikeRoute.steps) {
                        bikingDistance += routeStep.distance;
                        NSNumber *distance = [NSNumber numberWithFloat:routeStep.distance];
                        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:routeStep.instructions, @"instructions", distance, @"distance", @"biking", @"transportType", nil];
                        [self.routeDictionaries addObject:dictionary];
                        }
                self.bikeRouteDistanceString = [NSString stringWithFormat:@"%.01f", bikingDistance * 0.000621371];
                self.distanceCounter += bikingDistance;
            // Create third directions request and parameters (DivvyStation near destination to destination).
            MKDirectionsRequest *directionsRequest3 = [MKDirectionsRequest new];
            directionsRequest3.source = stationNearDestinationMapItem;
            directionsRequest3.destination = destinationMapItem;
            directionsRequest3.transportType =MKDirectionsTransportTypeWalking;
            MKDirections *directions3 = [[MKDirections alloc] initWithRequest:directionsRequest3];
            [directions3 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Unable to find a route for this trip" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                    self.activityIndicator.hidden = YES;
                    [self.activityIndicator stopAnimating];
                    [self enableUI];
                }
                else {
                    NSLog(@"Route 3 found");
                    NSArray *routeItems3 = response.routes;
                    self.walkroute2 = [routeItems3 firstObject];
                    self.etaCounter += (self.walkroute2.expectedTravelTime);
                    CGFloat walkRoute2Distance = 0.0f;
                        for (MKRouteStep *routeStep in self.walkroute2.steps) {
                            walkRoute2Distance += routeStep.distance;
                            NSNumber *distance = [NSNumber numberWithFloat:routeStep.distance];
                            NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:routeStep.instructions, @"instructions",distance, @"distance", @"walking", @"transportType", nil];
                            [self.routeDictionaries addObject:dictionary];
                        }

                    self.walkRoute2DistanceString = [NSString stringWithFormat:@"%.01f", walkRoute2Distance * 0.000621371];
                    self.distanceCounter +=walkRoute2Distance;

                // Add route overlays to the map
                [self.mapView addOverlay:self.walkRoute1.polyline];
                [self.mapView addOverlay:self.bikeRoute.polyline];
                [self.mapView addOverlay:self.walkroute2.polyline];

                //Assign total distance strings.
                self.totalDistanceString = [NSString stringWithFormat:@"%.01f", self.distanceCounter * 0.000621371];
                NSInteger travelTimeMinutes = self.etaCounter/60;
                self.travelTimeString = [NSString stringWithFormat:@"%ld", (long)travelTimeMinutes];

                [self.tableView reloadData];
                [self dropPins];
                [self createLineViews];
                [self enableUI];
                }
            }];
          }
       }];
     }
  }];
}

-(void)dropPins
{
    NSLog(@"DropPins method ran");

    // Add the annotation for the origin point.
    DestinationAnnotation *originAnnotation = [[DestinationAnnotation alloc] init];
    originAnnotation.coordinate = self.originPlacemark.coordinate;
    originAnnotation.title = self.originPlacemark.name;
    [self.mapView addAnnotation:originAnnotation];

    // Create an annotation for the destination point.
    DestinationAnnotation *destinationAnnotation = [[DestinationAnnotation alloc] init];
    destinationAnnotation.coordinate = self.destinationPlacemark.coordinate;
    destinationAnnotation.title = self.destinationPlacemark.name;
    [self.mapView addAnnotation:destinationAnnotation];

    // Add the origin Divvy map annotation.
    for (DivvyStation *divvyStation in self.stationsNearOrigin) {
        DivvyBikeAnnotation *annotation = [[DivvyBikeAnnotation alloc] init];
        annotation.title = divvyStation.stationName;
        annotation.subtitle = [NSString stringWithFormat:@"%@ mi. from %@ | Bikes: %@", self.walkRoute1DistanceString, self.userLocationString, divvyStation.availableBikes];
        annotation.coordinate = divvyStation.coordinate;
        annotation.imageName = @"Divvy";
        annotation.backgroundColor = divvyStation.bikesColor;
        annotation.annotationSize = divvyStation.annotationSize;
        [self.mapView addAnnotation:annotation];
    }

    // Add the destination Divvy map annotation.
    for (DivvyStation *divvyStation in self.stationsNearDestination) {
        DivvyBikeAnnotation *annotation = [[DivvyBikeAnnotation alloc] init];
        annotation.title = divvyStation.stationName;
        annotation.subtitle = [NSString stringWithFormat:@"%@ mi. from %@ | Docks: %@", self.walkRoute1DistanceString, self.userDestinationString, divvyStation.availableDocks];
        annotation.coordinate = divvyStation.coordinate;
        annotation.imageName = @"Divvy";
        annotation.backgroundColor = divvyStation.bikesColor;
        annotation.annotationSize = divvyStation.annotationSize;
        [self.mapView addAnnotation:annotation];
    }

    // Call helper method for redrawing the map to the proper size.
    [self redrawMapViewWithCurrentLocation:self.originPlacemark.coordinate andDestination:self.destinationPlacemark.coordinate];
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}

-(void)createLineViews
{
    NSLog(@"Map information view created");
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat containerViewHeight = 75.0f;
    CGFloat containerViewWidth = 150.0f;
    CGFloat horizontalOffset = self.view.frame.origin.x;
    CGFloat verticalOffset = self.view.frame.size.height -tabBarHeight - containerViewHeight;

    self.mapContainerView = [[UIView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, containerViewWidth, containerViewHeight)];
    [self.view addSubview:self.mapContainerView];

    NSMutableArray *viewsArray = [NSMutableArray new];

    UIView *bikeRouteView = [[UIView alloc] init];
    bikeRouteView.backgroundColor = [UIColor divvyColor];
    UIView *walkingRouteView = [[UIView alloc] init];
    walkingRouteView.backgroundColor = [UIColor walkRouteColor];

    [viewsArray addObject:bikeRouteView];
    [viewsArray addObject:walkingRouteView];

    CGFloat viewWidth = 25.0f;
    CGFloat viewHeight = 5.0f;
    horizontalOffset = 10.0f;
    verticalOffset = 10.0f;

    for (UIView *view in viewsArray) {
        view.frame = CGRectMake(horizontalOffset, verticalOffset, 1, viewHeight);
        [self.mapContainerView addSubview:view];

        //Style view
        view.layer.cornerRadius = 2.5f;

        // Add animation to expand the view outward
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.0];
        [UIView setAnimationDelay:0.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];

        view.frame = CGRectMake(horizontalOffset, verticalOffset, viewWidth, viewHeight);
        verticalOffset += viewHeight + 28.f;

        [UIView commitAnimations];
    }

    CGFloat imageViewWidth = 35.0f;
    CGFloat imageViewHeight = 25.0f;
    horizontalOffset += walkingRouteView.frame.size.width + 5.0f;
    verticalOffset = 0.0f;

    // Add imageviews
    UIImageView *bikeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    bikeImageView.image = [UIImage imageNamed:@"bluebike"];
    [self.mapContainerView addSubview:bikeImageView];

    verticalOffset += bikeImageView.frame.size.height + 5.0f;
    CGFloat imageViewWidth2 = 20.0f;
    CGFloat imageViewHeight2 = 35.0f;

    UIImageView *walkingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth2, imageViewHeight2)];
    walkingImageView.image = [UIImage imageNamed:@"redwalker"];
    [self.mapContainerView addSubview:walkingImageView];

    if (self.toggleIndex == 1) {
        self.mapContainerView.hidden = YES;
    }
}

#pragma mark - Tableview methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
        return 4;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
        }
    else if (section == 1) {
        return self.stationsNearOrigin.count;
        }
    else if (section == 2) {
        return self.stationsNearDestination.count;
        }
    else {
        return self.routeDictionaries.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Tableview cell with details of the user's trip.
        if (indexPath.section == 0) {
            TripTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tripcell"];
            // Set text of labels
            cell.tripLabel.text = [NSString stringWithFormat:@"From: %@\nTo: %@", self.userLocationString, self.userDestinationString];
            cell.distanceLabel.text = [NSString stringWithFormat:@"Distance: %@ miles", self.totalDistanceString];
            cell.etaLabel.text = [NSString stringWithFormat:@"Travel Time: %@ minutes", self.travelTimeString];

            // Set font of labels
            cell.titleLabel.font = [UIFont bigFontBold];
            cell.tripLabel.font = [UIFont mediumFontBold];
            cell.distanceLabel.font = [UIFont smallFont];
            cell.etaLabel.font = [UIFont smallFont];
            // Set textcolor of labels
            cell.tripLabel.textColor = [UIColor blackColor];
            cell.distanceLabel.textColor = [UIColor blackColor];
            cell.etaLabel.textColor = [UIColor blackColor];
            cell.titleLabel.textColor = [UIColor blackColor];
            // Style the cell
            cell.backgroundColor = [UIColor whiteColor];
            return cell;
        }

    // Tableview cell with details about the Divvy Station nearest their origin.
        else if (indexPath.section == 1) {
            BikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            DivvyStation *divvyStation = [self.stationsNearOrigin objectAtIndex:indexPath.row];

            // Set title labels text
            cell.titleLabel.text = @"Nearest Divvy Station";
            cell.stationLabel.text = divvyStation.stationName;
            cell.bikesLabel.text = [NSString stringWithFormat:@"Bikes\n%@", divvyStation.availableBikes.description];
            cell.docksLabel.text = [NSString stringWithFormat:@"Docks\n%@", divvyStation.availableDocks.description];
            cell.distanceLabel.text = [NSString stringWithFormat:@"%@ miles from %@", self.walkRoute1DistanceString, self.userLocationString];

            // Set title labels font
            cell.titleLabel.font = [UIFont mediumFontBold];
            cell.bikesLabel.font = [UIFont mediumFontBold];
            cell.docksLabel.font = [UIFont mediumFontBold];
            cell.distanceLabel.font = [UIFont smallFont];
            cell.stationLabel.font = [UIFont mediumFont];

            // Set title labels textcolor
            cell.titleLabel.textColor = [UIColor blackColor];
            cell.bikesLabel.textColor = [UIColor blackColor];
            cell.docksLabel.textColor = [UIColor blackColor];
            cell.distanceLabel.textColor = [UIColor blackColor];
            cell.stationLabel.textColor = [UIColor blackColor];

            // Set Bikes and Docks label styles
            cell.bikesLabel.backgroundColor = divvyStation.bikesColor;
            cell.bikesLabel.layer.borderWidth = 1.0f;
            cell.bikesLabel.layer.borderColor = [[UIColor blackColor] CGColor];
            cell.docksLabel.backgroundColor = divvyStation.docksColor;
            cell.docksLabel.layer.borderWidth = 1.0f;
            cell.docksLabel.layer.borderColor = [[UIColor blackColor] CGColor];

            // Style the cell
            cell.backgroundColor = [UIColor whiteColor];

            return cell;
        }

    // Tableview cell with details about the Divvy Station nearest to the destination.
        else if (indexPath.section == 2)  {
            BikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            DivvyStation *divvyStation = [self.stationsNearDestination objectAtIndex:indexPath.row];

            // Set title labels text
            cell.titleLabel.text = @"Destination Divvy Station";
            cell.stationLabel.text = divvyStation.stationName;
            cell.bikesLabel.text = [NSString stringWithFormat:@"Bikes\n%@", divvyStation.availableBikes.description];
            cell.docksLabel.text = [NSString stringWithFormat:@"Docks\n%@", divvyStation.availableDocks.description];
            cell.distanceLabel.text = [NSString stringWithFormat:@"%@ miles from %@", self.walkRoute2DistanceString, self.userDestinationString];

            // Set title labels font
            cell.titleLabel.font = [UIFont mediumFontBold];
            cell.stationLabel.font = [UIFont mediumFont];
            cell.bikesLabel.font = [UIFont mediumFontBold];
            cell.docksLabel.font = [UIFont mediumFontBold];
            cell.distanceLabel.font = [UIFont smallFont];

            // Set title labels textcolor
            cell.titleLabel.textColor = [UIColor blackColor];
            cell.stationLabel.textColor = [UIColor blackColor];
            cell.bikesLabel.textColor = [UIColor blackColor];
            cell.docksLabel.textColor = [UIColor blackColor];
            cell.distanceLabel.textColor = [UIColor blackColor];

            // Set Bikes and Docks label styles

            cell.bikesLabel.backgroundColor = divvyStation.bikesColor;
            cell.bikesLabel.layer.borderWidth = 1.0f;
            cell.bikesLabel.layer.borderColor = [[UIColor blackColor] CGColor];
            cell.docksLabel.backgroundColor = divvyStation.docksColor;
            cell.docksLabel.layer.borderWidth = 1.0f;
            cell.docksLabel.layer.borderColor = [[UIColor blackColor] CGColor];

            // Style the cell
            cell.backgroundColor = [UIColor whiteColor];

            return cell;
        }

    // Tableview cells with walking directions for the first leg of the trip
        else  {
            RouteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"routecell"];
            NSDictionary *dictionary = [self.routeDictionaries objectAtIndex:indexPath.row];

            cell.stepLabel.font = [UIFont bigFont];
            cell.stepLabel.textColor = [UIColor whiteColor];

            if ([[dictionary objectForKey:@"transportType"] isEqualToString:@"walking"]) {
                cell.backgroundColor = [UIColor walkRouteColor];
                cell.transportModeImageView.image = [UIImage imageNamed:@"Walking"];
            }
            else {
                cell.backgroundColor = [UIColor divvyColor];
                cell.transportModeImageView.image = [UIImage imageNamed:@"bicycle"];
            }

            NSString *distanceString = [NSString new];
            if ([[dictionary objectForKey:@"distance"] floatValue] < 170.0f) {
                CGFloat distance = [[dictionary objectForKey:@"distance"] floatValue] * 3.28084;
                distanceString = [NSString stringWithFormat:@"%.0f feet", distance];
            }
            else {
                CGFloat distance = [[dictionary objectForKey:@"distance"] floatValue] * 0.000621371;
                distanceString = [NSString stringWithFormat:@"%.01f miles", distance];
            }

            // First element in a routeSteps array always has distance 0.00, so not necessary to display it.
            if ([[dictionary objectForKey:@"distance"] floatValue] == 0.0f) {
                cell.stepLabel.text = [dictionary objectForKey:@"instructions"];
            }

            // For the last element in the array keep "The destination", else replace "the destination" with Divvy Station.
            else if (![dictionary isEqual:[self.routeDictionaries lastObject]]) {

                // Find the instructions string
                NSString *instructions = [dictionary objectForKey:@"instructions"];

                // Replace upper case "The destination"
                NSString *instructionsNew = [instructions stringByReplacingOccurrencesOfString:@"The destination" withString:@"Divvy Station"];

                // Replace lower case "the destination"
                NSString *instructionsNew2 = [instructionsNew stringByReplacingOccurrencesOfString:@"the destination" withString:@"Divvy Station"];
                // Set cell label text by adding distance to the end of the reformatted instructions
                cell.stepLabel.text = [instructionsNew2 stringByAppendingString:[NSString stringWithFormat:@" in %@", distanceString]];
            }
            else {
                cell.stepLabel.text = [NSString stringWithFormat:@"%@ in %@", [dictionary objectForKey:@"instructions"], distanceString];
            }

            // If its the Divvy Step
            if ([cell.stepLabel.text rangeOfString:@"Divvy"].location == NSNotFound) {
                NSLog(@"string does not contain Divvy");
            }
            else {
                cell.transportModeImageView.image = [UIImage imageNamed:@"DivvyLogo"];
                cell.transportModeImageView.layer.cornerRadius = 5.0f;
                cell.transportModeImageView.clipsToBounds = YES;
                cell.backgroundColor = [UIColor blackColor];
            }

        return cell;
     }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 100.0f;
    }
    else if (indexPath.section == 1) {
        return 80.0f;
    }
    else if (indexPath.section == 2) {
        return 80.0f;
    }
    else {
        return 75.0f;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 3) {
        return 35.0f;
    }
    else{
        return 0.0f;
    }
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
    /* Create custom view to display section header... */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 30)];
    [label setFont:[UIFont bigFontBold]];
    NSString *string = @"Route Directions";
    /* Section header is in 0th index... */
    [label setText:string];
    [label setTextColor:[UIColor blackColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:label];
    [view setBackgroundColor:[UIColor whiteColor]];
    return view;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        self.selectedStation = [self.stationsNearOrigin firstObject];
        [self performSegueWithIdentifier:@"station" sender:self];
    }
    else if (indexPath.section == 2) {
        self.selectedStation = [self.stationsNearDestination firstObject];
        [self performSegueWithIdentifier:@"station" sender:self];
    }
    else
    {
        self.selectedRouteDictionary = [self.routeDictionaries objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"routedetails" sender:self];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"station"]) {
    DivvyStation *station = self.selectedStation;
    StationDetailViewController *detailViewController = segue.destinationViewController;
    detailViewController.stationFromSourceVC = station;
    detailViewController.userLocationFromSourceVC = self.userLocation;
    detailViewController.userLocationStringFromSource = self.userLocationString;
    }
    else if ([segue.identifier isEqualToString:@"routedetails"]) {
        RouteDetailsViewController *detailViewController = segue.destinationViewController;
        detailViewController.routeDictionaries = self.routeDictionaries;
        detailViewController.selectedRouteDictionary = self.selectedRouteDictionary;
    }
}

#pragma mark - mapview methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:MKUserLocation.class]) {
        return nil;
    }
    
    else if ([annotation isKindOfClass:[DivvyBikeAnnotation class]]) {
        DivvyBikeAnnotation *divvyAnnotation = annotation;
        static NSString *annotationIdentifier = @"MyAnnotation";
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
            if (!annotationView) {
                annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
                annotationView.canShowCallout = YES;
                annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            }
            else {
                annotationView.annotation = annotation;
            }
            annotationView.image = [UIImage imageNamed:divvyAnnotation.imageName];
            annotationView.frame = CGRectMake(0, 0, divvyAnnotation.annotationSize, divvyAnnotation.annotationSize);
            annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
            annotationView.backgroundColor = divvyAnnotation.backgroundColor;

        return annotationView;
    }

    else {
        return nil;
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isEqual:self.walkRoute1.polyline]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.strokeColor = [UIColor walkRouteColor];
        renderer.lineWidth = 4.0;
        return  renderer;
    }
    else if ([overlay isEqual:self.bikeRoute.polyline]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.strokeColor = [UIColor divvyColor];
        renderer.lineWidth = 4.0;
        return  renderer;
    }
    else {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.strokeColor = [UIColor walkRouteColor];
        renderer.lineWidth = 4.0;
        return  renderer;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"station" sender:self];
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKPinAnnotationView *)view
{
    if ([[[self.stationsNearOrigin firstObject] stationName] isEqual:view.annotation.title]) {
        self.selectedStation = [self.stationsNearOrigin firstObject];
    }
    else if ([[[self.stationsNearDestination firstObject] stationName] isEqual:view.annotation.title]) {
        self.selectedStation = [self.stationsNearDestination firstObject];
    }
}

#pragma mark - Segmented Control methods

- (void)segmentChanged:(id)sender
{
    if ([sender selectedSegmentIndex] == 0) {
        self.mapView.hidden = NO;
        self.mapContainerView.hidden = NO;
        self.toggleIndex = 0;
        self.segmentedControl.layer.borderColor = [[UIColor divvyColor] CGColor];
    }
    else
    {
        self.mapView.hidden = YES;
        self.tableView.hidden = NO;
        self.mapContainerView.hidden = YES;
        self.toggleIndex = 1;
        self.segmentedControl.layer.borderColor = [[UIColor whiteColor] CGColor];
    }
}
- (IBAction)onSegmentControlToggle:(id)sender
{
    [self segmentChanged:sender];
}

#pragma mark - helper methods

- (void)getUserLocationString
{
    if (self.userLocation) {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:self.userLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            for (CLPlacemark *placemark in placemarks) {
                if (placemarks.count < 1) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to find your current location" message:@"Please try again later" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                    NSLog(@"No current location found");
                }
                else {
                        CLPlacemark *pmark = [placemarks firstObject];
                        self.userLocationString = ABCreateStringWithAddressDictionary(pmark.addressDictionary, NO);
                        self.fromTextFieldOutlet.text = self.userLocationString;
                        NSLog(@"User Location: %@", self.userLocationString);
                        break;
                }
            }
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
        [self enableUI];
        }];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to find your current location" message:@"Make sure you have allowed Divvy & Conquer to user your current location" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        NSLog(@"No current location found");
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
        [self enableUI];
    }
}

// Scales the map view appropriately to include both origin and destination location.
-(void)redrawMapViewWithCurrentLocation:(CLLocationCoordinate2D)userLocation andDestination:(CLLocationCoordinate2D)desinationLocation
{
    CLLocationCoordinate2D topLeftCoord;
    CLLocationCoordinate2D bottomRightCoord;

    topLeftCoord.longitude = fmin(userLocation.longitude, desinationLocation.longitude);
    topLeftCoord.latitude = fmax(userLocation.latitude, desinationLocation.latitude);

    bottomRightCoord.longitude = fmax(userLocation.longitude, desinationLocation.longitude);
    bottomRightCoord.latitude = fmin(userLocation.latitude, desinationLocation.latitude);

    MKCoordinateRegion region;
    //MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;

    // Adding some buffer space to the mapview
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.5;
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.5;

    region = [self.mapView regionThatFits:region];
    [self.mapView setRegion:region animated:YES];

    NSLog(@"Map redrawn");
}

-(void)setStyle
{
    // Set navigation bar title label
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat labelWidth = 200.0f;
    CGFloat labelHeight = 25.0f;
    CGFloat horizontalOffset = (self.view.frame.size.width/2) - (labelWidth/2);
    CGFloat verticalOffset = statusBarHeight + (navBarHeight/2);
    UILabel *navigationBarLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];

    navigationBarLabel.text = @"Divvy & Conquer";
    navigationBarLabel.textColor = [UIColor whiteColor];
    navigationBarLabel.textAlignment = NSTextAlignmentCenter;
    navigationBarLabel.font = [UIFont bigFontBold];
    self.navigationItem.titleView = navigationBarLabel;

    //Segmented control
    self.segmentedControl.backgroundColor = [UIColor divvyColor];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    self.segmentedControl.layer.borderColor = [[UIColor divvyColor] CGColor];
    self.segmentedControl.layer.borderWidth = 1.0f;
    self.segmentedControl.layer.cornerRadius = 5.0f;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont mediumFontBold]};
    [self.segmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];

    // Activity indicator
    self.activityIndicator.color = [UIColor divvyColor];

    //Tableview
    self.tableView.separatorColor = [UIColor blackColor];
    self.tableView.backgroundColor = [UIColor divvyColor];

    //Cancel button
    [self.cancelButtonOutlet setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButtonOutlet setBackgroundColor:[UIColor divvyColor]];
    self.cancelButtonOutlet.layer.cornerRadius = 5.0f;
    self.cancelButtonOutlet.layer.borderWidth = 1.0f;
    self.cancelButtonOutlet.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.cancelButtonOutlet.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.cancelButtonOutlet.titleLabel setFont:[UIFont smallFontBold]];

    //Current location button
    self.currentLocationButtonOutlet.layer.cornerRadius = 5.0f;
    [self.currentLocationButtonOutlet setImage:[UIImage imageNamed:@"location-icon"] forState:UIControlStateNormal];
    [self.currentLocationButtonOutlet setTintColor:[UIColor whiteColor]];
    self.currentLocationButtonOutlet.layer.borderWidth = 1.0f;
    self.currentLocationButtonOutlet.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.currentLocationButtonOutlet setBackgroundColor:[UIColor divvyColor]];

    // From search bar
    self.fromTextFieldOutlet.layer.cornerRadius = 5.0f;
    [self.fromTextFieldOutlet setTextColor:[UIColor divvyColor]];
    self.fromTextFieldOutlet.font = [UIFont smallFont];

    // To search bar
    self.destinationTextFieldOutlet.layer.cornerRadius = 5.0f;
    [self.destinationTextFieldOutlet setTextColor:[UIColor divvyColor]];
    self.destinationTextFieldOutlet.font = [UIFont smallFont];

    // Background view
    self.view.backgroundColor = [UIColor divvyColor];
    self.tableViewBlockerView.backgroundColor = [UIColor divvyColor];
}

-(void)setStationColors:(NSArray *)stationsArray
{
    NSLog(@"Setting station annotation colors");
    // Dynamically update the background color from red -> yellow -> green
    // The blue color is not in this spectrum, thus it is always 0.
    CGFloat blue = 0.0f/255.0f;

    for (DivvyStation *divvyStation in stationsArray) {

        // Set values
        CGFloat totalDocks = divvyStation.availableDocks.floatValue + divvyStation.availableBikes.floatValue;
        CGFloat bikesFractionOfTotal = divvyStation.availableBikes.floatValue/totalDocks;
        CGFloat docksFractionOfTotal = divvyStation.availableDocks.floatValue/totalDocks;
        CGFloat availableBikes = divvyStation.availableBikes.floatValue;
        CGFloat availableDocks = divvyStation.availableDocks.floatValue;

        // Find bikes color
        // If ratio is less than half, apply max red and adjust green level accordingly
        if (bikesFractionOfTotal < 0.5f) {
            CGFloat red = 1.0f;
            CGFloat green = 1 - (((totalDocks/2) - availableBikes)/(totalDocks/2));
            divvyStation.bikesColor =[UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        }
        // If ratio is less than half, apply max green and adjust red level accordingly
        else if (bikesFractionOfTotal > 0.5f) {
            CGFloat green = 1.0f;
            CGFloat red = 1-(((availableBikes - totalDocks/2))/(totalDocks/2));
            divvyStation.bikesColor =[UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        }
        // Else, fraction is 0.5, apply maxRGB for both green and red (pure yellow)
        else {
            CGFloat red = 1.0f;
            CGFloat green = 1.0f;
            divvyStation.bikesColor =[UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        }

        // Find docks color
        // If ratio is less than half, apply max red and adjust green level accordingly
        if (docksFractionOfTotal < 0.5f) {
            CGFloat red = 1.0f;
            CGFloat green = 1 - (((totalDocks/2) - availableDocks)/(totalDocks/2));
            divvyStation.docksColor =[UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        }
        // If ratio is less than half, apply max green and adjust red level accordingly
        else if (docksFractionOfTotal > 0.5f) {
            CGFloat green = 1.0f;
            CGFloat red = 1-(((availableDocks - totalDocks/2))/(totalDocks/2));
            divvyStation.docksColor =[UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        }
        // Else, fraction is 0.5, apply maxRGB for both green and red (pure yellow)
        else {
            CGFloat red = 1.0f;
            CGFloat green = 1.0f;
            divvyStation.docksColor =[UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        }
    }
}

-(void)disableUI
{
    NSLog(@"Disabling UI");
    self.fromTextFieldOutlet.enabled = NO;
    self.destinationTextFieldOutlet.enabled = NO;
    self.currentLocationButtonOutlet.enabled = NO;
    self.cancelButtonOutlet.enabled = NO;
}

-(void)enableUI
{
    NSLog(@"Enabling UI");
    self.fromTextFieldOutlet.enabled = YES;
    self.destinationTextFieldOutlet.enabled = YES;
    self.currentLocationButtonOutlet.enabled = YES;
    self.cancelButtonOutlet.enabled = YES;
}


@end
