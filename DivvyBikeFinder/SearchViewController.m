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
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

@interface SearchViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property CLLocation *userLocation;
@property CLLocation *chicago;
@property CLLocationManager *locationManager;
@property MKPlacemark *originPlacemark;
@property MKPlacemark *destinationPlacemark;
@property NSArray *divvyStations;
@property NSArray *stationsNearOrigin;
@property NSArray *stationsNearDestination;
@property NSArray *bikerouteSteps;
@property NSArray *walkrouteSteps1;
@property NSArray *walkrouteSteps2;
@property NSString *userLocationString;
@property NSString *userDestinationString;
@property NSString *distanceToDestinationString;
@property NSString *travelTimeString;
@property MKRoute *bikeRoute;
@property MKRoute *walkRoute1;
@property MKRoute *walkroute2;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *currentLocationButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *cancelButtonOutlet;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *fromTextFieldOutlet;
@property (weak, nonatomic) IBOutlet UITextField *destinationTextFieldOutlet;
@property (weak, nonatomic) IBOutlet UIView *tableViewBlockerView;
@property UIView *mapContainerView;
@property BOOL currentLocationButtonPressed;
@property CGFloat distanceCounter;
@property CGFloat etaCounter;
@property NSInteger toggleIndex;

@end

@implementation SearchViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Instantiate a location for the city of Chicago (used for handling cases when users are not in Chicago)
    self.chicago = [[CLLocation alloc] initWithLatitude:41.891813 longitude:-87.647343];

    // Instantiate location manager and start updating user location.
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager startUpdatingLocation];

    // Set delegates
    self.destinationTextFieldOutlet.delegate = self;
    self.fromTextFieldOutlet.delegate = self;
    self.locationManager.delegate = self;

    // Set correct views to show or be hidden.
    self.mapView.hidden = NO;
    self.tableView.hidden = YES;
    self.currentLocationButtonPressed = NO;
    self.segmentedControl.hidden = YES;
    self.toggleIndex = 0;
    self.currentLocationButtonOutlet.enabled = NO;

    // Helper method for styling views
    [self setStyle];

    // Get DivvyBike Data
    [self getJSON];
}


#pragma mark - Location manager methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000) {
            [self.locationManager stopUpdatingLocation];

            // Set the user location property.
            self.userLocation = location;
            [self getUserLocationString];
            CGFloat userDistanceFromChicago = [self.chicago distanceFromLocation:self.userLocation];

            // If user is too far from Chicago, map will default to the Chicago area.
            // 80,466 meters is 50 miles, approximately.
            if (userDistanceFromChicago > 80466) {
                CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(self.chicago.coordinate.latitude, self.chicago.coordinate.longitude);
                MKCoordinateSpan span = MKCoordinateSpanMake(.1, .1);
                MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
                self.mapView.showsUserLocation = YES;
                [self.mapView setRegion:region animated:YES];
                break;
            }
            // If user is in Chicago, draw map around their location.
            else {
                CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(self.userLocation.coordinate.latitude, self.   userLocation.coordinate.longitude);
                MKCoordinateSpan span = MKCoordinateSpanMake(.03, .03);
                MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
                self.mapView.showsUserLocation = YES;
                [self.mapView setRegion:region animated:YES];
                break;
            }
        }
    }
}

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

                 [tempArray addObject:divvyStation];
             }

             NSSortDescriptor *distanceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
             NSArray *sortDescriptors = @[distanceDescriptor];
             NSArray *divvyStationsArray = [NSArray arrayWithArray:tempArray];
             self.divvyStations = [divvyStationsArray sortedArrayUsingDescriptors:sortDescriptors];

             self.activityIndicator.hidden = YES;
             [self.activityIndicator stopAnimating];
         }
     }];
}

#pragma mark - IBActions

- (IBAction)onCancelButtonPressed:(id)sender
{
    self.userDestinationString = nil;
    self.fromTextFieldOutlet.text = nil;
    self.destinationTextFieldOutlet.text = nil;

    self.currentLocationButtonOutlet.enabled = YES;

    [self.fromTextFieldOutlet endEditing:YES];
    [self.destinationTextFieldOutlet endEditing:YES];
}

- (IBAction)onCurrentLocationButtonPressed:(id)sender
{
    // Show activity indicator
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];

    self.currentLocationButtonOutlet.enabled = NO;
    self.currentLocationButtonPressed = YES;
    [self.locationManager startUpdatingLocation];
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

            // Clear map of annotations
            [self.mapView removeAnnotations:self.mapView.annotations];

            // Reveal the segmented control, so users can see route details.
            self.segmentedControl.hidden = NO;

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
            NSLog(@"Origin name found");
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
            NSLog(@"Origin address found");
            [self getDestinationFromName];
            }
        else {
            // Show alert that origin result was not found.
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:[NSString stringWithFormat:@"No results found matching %@", self.userLocationString] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            self.activityIndicator.hidden = YES;
            [self.activityIndicator stopAnimating];
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
            [self dropPins];
            NSLog(@"Destination name found");
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
            [self dropPins];
            NSLog(@"Destination address found");
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:[NSString stringWithFormat:@"No results found matching %@", self.userDestinationString] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            self.activityIndicator.hidden = YES;
            [self.activityIndicator stopAnimating];
        }
    }];
}

// If origin and destination placemarks are found, create pin annotations.
-(void)dropPins
{
    NSLog(@"DropPins method ran");

    // If both origin and destinations have been found...
    if (self.destinationPlacemark && self.originPlacemark) {

        // Create CLLoction objects for origin and destination placemarks
        CLLocation *originLocation = [[CLLocation alloc] initWithLatitude:self.originPlacemark.coordinate.latitude longitude:self.originPlacemark.coordinate.longitude];
        CLLocation *destinationLocation = [[CLLocation alloc] initWithLatitude:self.destinationPlacemark.coordinate.latitude longitude:self.destinationPlacemark.coordinate.longitude];

        // Include logic that makes sure the origin and destination locations are within an acceptable area around Chicago.
        CGFloat originDistanceFromChicago = [self.chicago distanceFromLocation:originLocation];
        CGFloat destinationDistanceFromChicago = [self.chicago distanceFromLocation:destinationLocation];

        // 40,233 meters is 25 miles, approximately.
        if (originDistanceFromChicago > 40233.6) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:[NSString stringWithFormat:@"%@ not found in Chicago", self.userLocationString] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            self.activityIndicator.hidden = YES;
            [self.activityIndicator stopAnimating];
        }
        else if (destinationDistanceFromChicago > 40233.6) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:[NSString stringWithFormat:@"%@ not found in Chicago", self.userDestinationString] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            self.activityIndicator.hidden = YES;
            [self.activityIndicator stopAnimating];
        }
        else {
        // Reassign destination and origin string names to those provided by the placemark.
            self.userLocationString = self.originPlacemark.name;
            self.userDestinationString = self.destinationPlacemark.name;

        // Create an annotation for the origin point.
        DestinationAnnotation *originAnnotation = [[DestinationAnnotation alloc] init];
        originAnnotation.coordinate = self.originPlacemark.coordinate;
        originAnnotation.title = self.originPlacemark.name;
        [self.mapView addAnnotation:originAnnotation];

        // Create an annotation for the destination point.
        DestinationAnnotation *destinationAnnotation = [[DestinationAnnotation alloc] init];
        destinationAnnotation.coordinate = self.destinationPlacemark.coordinate;
        destinationAnnotation.title = self.destinationPlacemark.name;
        CGFloat distanceToDestination = [originLocation distanceFromLocation:destinationLocation];
        destinationAnnotation.subtitle = [NSString stringWithFormat:@"Distance: %.01f miles", distanceToDestination * 0.000621371];
        [self.mapView addAnnotation:destinationAnnotation];

        // Call helper method for redrawing the map to the proper size.
        [self redrawMapViewWithCurrentLocation:self.originPlacemark.coordinate andDestination:self.destinationPlacemark.coordinate];

        // Search for the closest Divvy Stations to the origin and destination points.
        [self findDivvyStations:originLocation andDestination:destinationLocation];
        }
    }
}

-(void)findDivvyStations:(CLLocation *)originLocation andDestination:(CLLocation *)destinationLocation
{
    NSLog(@"Find DivvyStations method ran");

    // For all the Divvy stations reassign the "distance from user" property to be the distance from the search origin.
    NSMutableArray *tempArray = [NSMutableArray new];
    for (DivvyStation *divvyStation in self.divvyStations) {
        CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:divvyStation.latitude.floatValue longitude:divvyStation.longitude.floatValue];
        divvyStation.distanceFromUser = [originLocation distanceFromLocation:stationLocation];
        [tempArray addObject:divvyStation];
    }

    // Sort the temporary array by distance from origin
    NSSortDescriptor *originDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
    NSArray *originDescriptors = @[originDescriptor];
    NSArray *divvyStationsArray1 = [tempArray sortedArrayUsingDescriptors:originDescriptors];

    // Find nearest Divvy Stations to user, provided it has available bikes, and add to stationsNearOriginArray.
    NSInteger counter = 0;
    NSMutableArray *tempArray1 = [NSMutableArray new];
    while (counter < 1) {
        DivvyStation *divvyStation = [divvyStationsArray1 objectAtIndex:counter];
        if (divvyStation.availableBikes.floatValue > 0) {
            [tempArray1 addObject:divvyStation];
            DivvyBikeAnnotation *divvyBikesPin = [[DivvyBikeAnnotation alloc] init];
            divvyBikesPin.coordinate = divvyStation.coordinate;
            [self.mapView addAnnotation:divvyBikesPin];
        }
        counter += 1;
    }
    self.stationsNearOrigin = [NSArray arrayWithArray:tempArray1];

    // Find nearest Divvy Station to the user's destination, provided it has available docks, and add to stationsNearDestinationArray.

    // Assign the distanceFromDestination property to each station in the divvyStations array.
    NSMutableArray *tempArray2 = [NSMutableArray new];
    for (DivvyStation *divvyStation in self.divvyStations) {
        CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:divvyStation.latitude.floatValue longitude:divvyStation.longitude.floatValue];
        divvyStation.distanceFromDestination = [destinationLocation distanceFromLocation:stationLocation];
        [tempArray2 addObject:divvyStation];
    }

    // Sort the temporary array by distance to destination
    NSSortDescriptor *destinationDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromDestination" ascending:YES];
    NSArray *destinationDescriptors = @[destinationDescriptor];
    NSArray *divvyStationsArray2 = [tempArray2 sortedArrayUsingDescriptors:destinationDescriptors];

    // Find closest station to the user's destination, provided docks are available.
    NSInteger counter2 = 0;
    NSMutableArray *tempArray3 = [NSMutableArray new];
    while (counter2 < 1) {
        DivvyStation *divvyStation = [divvyStationsArray2 objectAtIndex:counter2];
        if (divvyStation.availableDocks.floatValue > 0) {
            [tempArray3 addObject:divvyStation];

            DivvyBikeAnnotation *divvyBikesPin = [[DivvyBikeAnnotation alloc] init];
            divvyBikesPin.coordinate = divvyStation.coordinate;
            [self.mapView addAnnotation:divvyBikesPin];
        }
        counter2 += 1;
    }
    self.stationsNearDestination = [NSArray arrayWithArray:tempArray3];


    if (self.stationsNearDestination.count > 0 && self.stationsNearOrigin.count > 0) {
        NSLog(@"Stations near origin and destination found");
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Unable to locate nearby Divvy Bike stations" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }

    [self getDirections];
}

#pragma mark - Directions methods

-(void)getDirections
{
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

        NSArray *routeItems1 = response.routes;
        self.walkRoute1 = [routeItems1 firstObject];
        self.walkrouteSteps1 = self.walkRoute1.steps;

        self.etaCounter += self.walkRoute1.expectedTravelTime;
        for (MKRouteStep *routeStep in self.walkrouteSteps1) {
            self.distanceCounter += routeStep.distance;
        }

        // Create second directions request and parameters (DivvyStation to DivvyStation).
        MKDirectionsRequest *directionsRequest2 = [MKDirectionsRequest new];
        directionsRequest2.source = stationNearOriginMapItem;
        directionsRequest2.destination = stationNearDestinationMapItem;
        directionsRequest2.transportType =MKDirectionsTransportTypeWalking;

        MKDirections *directions2 = [[MKDirections alloc] initWithRequest:directionsRequest2];

        [directions2 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {

            NSArray *routeItems2 = response.routes;
            self.bikeRoute = [routeItems2 firstObject];
            self.bikerouteSteps = self.bikeRoute.steps;

            // Assumes cycling is about 3 times faster than walking (approx. biking speed assumption is between 9.0-9.5 MPH)
            self.etaCounter += (self.bikeRoute.expectedTravelTime/3);

            for (MKRouteStep *routeStep in self.bikerouteSteps) {
                self.distanceCounter += routeStep.distance;
            }

            // Create third directions request and parameters (DivvyStation near destination to destination).
            MKDirectionsRequest *directionsRequest3 = [MKDirectionsRequest new];
            directionsRequest3.source = stationNearDestinationMapItem;
            directionsRequest3.destination = destinationMapItem;
            directionsRequest3.transportType =MKDirectionsTransportTypeWalking;

            MKDirections *directions3 = [[MKDirections alloc] initWithRequest:directionsRequest3];

            [directions3 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {

                NSArray *routeItems3 = response.routes;
                self.walkroute2 = [routeItems3 firstObject];
                self.walkrouteSteps2 = self.walkroute2.steps;
                self.etaCounter += self.walkroute2.expectedTravelTime;
                for (MKRouteStep *routeStep in self.walkrouteSteps2) {
                    self.distanceCounter += routeStep.distance;
                }

                // Add route overlays to the map
                [self.mapView addOverlay:self.walkRoute1.polyline];
                [self.mapView addOverlay:self.bikeRoute.polyline];
                [self.mapView addOverlay:self.walkroute2.polyline];

                //Assign distance and travel time strings.
                self.distanceToDestinationString = [NSString stringWithFormat:@"%.01f miles", self.distanceCounter * 0.000621371];

                NSInteger travelTimeMinutes = self.etaCounter/60;
                self.travelTimeString = [NSString stringWithFormat:@"%ld min.", (long)travelTimeMinutes];

                self.activityIndicator.hidden = YES;
                [self.activityIndicator stopAnimating];

                [self.tableView reloadData];
                [self createLineViews];
            }];
        }];
    }];
}

-(void)createLineViews
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;

    self.mapContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, (self.view.frame.size.height -tabBarHeight) -65, 150, 60)];
    [self.view addSubview:self.mapContainerView];

    NSMutableArray *viewsArray = [NSMutableArray new];

    UIView *bikeRouteView = [[UIView alloc] init];
    bikeRouteView.backgroundColor = [UIColor divvyColor];
    UIView *walkingRouteView = [[UIView alloc] init];
    walkingRouteView.backgroundColor = [UIColor walkRouteColor];

    [viewsArray addObject:bikeRouteView];
    [viewsArray addObject:walkingRouteView];

    CGFloat viewWidth = 30.0f;
    CGFloat viewHeight = 5.0f;
    CGFloat horizontalOffset = 10.0f;
    CGFloat verticalOffset = 10.0f;

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
        verticalOffset += viewHeight + 20.f;

        [UIView commitAnimations];
    }

    // Add labels
    UILabel *bikeLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 0, 100, 25)];
    bikeLabel.text = @"Cycling";
    [self.mapContainerView addSubview:bikeLabel];

    UILabel *walkingLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 25, 100, 25)];
    walkingLabel.text = @"Walking";
    [self.mapContainerView addSubview:walkingLabel];

    if (self.toggleIndex == 1) {
        self.mapContainerView.hidden = YES;
    }
}

#pragma mark - Tableview methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
        return 6;
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
    else if (section == 3) {
        return self.walkrouteSteps1.count;
    }
    else if (section == 4) {
        return self.bikerouteSteps.count;
    }
    else if (section == 5) {
        return self.walkrouteSteps2.count;
    }
    else {
        return 0;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Tableview cell with details of the user's trip.
        if (indexPath.section == 0) {
            TripTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tripcell"];
            cell.tripLabel.text = [NSString stringWithFormat:@"From: %@\nTo: %@", self.userLocationString, self.userDestinationString];
            cell.distanceLabel.text = [NSString stringWithFormat:@"Distance: %@", self.distanceToDestinationString];
            cell.etaLabel.text = [NSString stringWithFormat:@"Travel Time: %@", self.travelTimeString];

            cell.backgroundColor = [UIColor whiteColor];
            cell.tripLabel.textColor = [UIColor divvyColor];
            cell.distanceLabel.textColor = [UIColor divvyColor];
            cell.etaLabel.textColor = [UIColor divvyColor];
            cell.titleLabel.textColor = [UIColor divvyColor];

            return cell;
        }

    // Tableview cell with details about the Divvy Station nearest their origin.
        else if (indexPath.section == 1) {
            BikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            DivvyStation *divvyStation = [self.stationsNearOrigin objectAtIndex:indexPath.row];

            cell.titleLabel.text = @"Nearest Station";
            cell.stationLabel.text = divvyStation.stationName;
            cell.bikesLabel.text = [NSString stringWithFormat:@"Bikes\n%@", divvyStation.availableBikes.description];
            cell.docksLabel.text = [NSString stringWithFormat:@"Docks\n%@", divvyStation.availableDocks.description];

            NSString *milesFromUser = [NSString stringWithFormat:@"%.01f miles from %@", divvyStation.distanceFromUser * 0.000621371, self.userLocationString];
            cell.distanceLabel.text = milesFromUser;

            cell.backgroundColor = [UIColor whiteColor];
            cell.stationLabel.textColor = [UIColor divvyColor];
            cell.distanceLabel.textColor = [UIColor divvyColor];
            cell.bikesLabel.textColor = [UIColor divvyColor];
            cell.docksLabel.textColor = [UIColor divvyColor];
            cell.titleLabel.textColor = [UIColor divvyColor];
            return cell;
        }

    // Tableview cell with details about the Divvy Station nearest to the destination.
        else if (indexPath.section == 2)  {
            BikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            DivvyStation *divvyStation = [self.stationsNearDestination objectAtIndex:indexPath.row];

            cell.titleLabel.text = @"Destination Station";
            cell.stationLabel.text = divvyStation.stationName;
            cell.bikesLabel.text = [NSString stringWithFormat:@"Bikes\n%@", divvyStation.availableBikes.description];
            cell.docksLabel.text = [NSString stringWithFormat:@"Docks\n%@", divvyStation.availableDocks.description];

            NSString *milesFromUser = [NSString stringWithFormat:@"%.01f miles from %@", divvyStation.distanceFromDestination * 0.000621371, self.userDestinationString];
            cell.distanceLabel.text = milesFromUser;

            cell.backgroundColor = [UIColor whiteColor];
            cell.stationLabel.textColor = [UIColor divvyColor];
            cell.distanceLabel.textColor = [UIColor divvyColor];
            cell.bikesLabel.textColor = [UIColor divvyColor];
            cell.docksLabel.textColor = [UIColor divvyColor];
            cell.titleLabel.textColor = [UIColor divvyColor];
            return cell;
        }

    // Tableview cells with walking directions for the first leg of the trip
        else if (indexPath.section == 3) {
            RouteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"routecell"];
            MKRouteStep *routeStep = [self.walkrouteSteps1 objectAtIndex:indexPath.row];

            // First element in a routeSteps array always has distance 0.00, so not necessary to display it.
            if ([routeStep isEqual:[self.walkrouteSteps1 firstObject]]) {
                cell.distanceLabel.text = @"";
                }
            else {
                CGFloat distance = routeStep.distance * 0.000621371;
                cell.distanceLabel.text = [NSString stringWithFormat:@"Distance\n%.02f mi.", distance];
                }
            // Last element in a routeSteps array says "The destination". I want "The destination" to be replaced by "Divvy Station"
            if ([routeStep isEqual:[self.walkrouteSteps1 lastObject]]) {

                // Find the instructions string
                NSString *instructions = [[self.walkrouteSteps1 lastObject] instructions];

                // Replace upper case "The destination"
                NSString *instructionsNew = [instructions stringByReplacingOccurrencesOfString:@"The destination" withString:@"Divvy Station"];

                // Replace lower case "the destination"
                NSString *instructionsNew2 = [instructionsNew stringByReplacingOccurrencesOfString:@"the destination" withString:@"Divvy Station"];

                // Set cell label text.
                cell.stepLabel.text = [NSString stringWithFormat:@"%@", instructionsNew2];

            }
            else {
                cell.stepLabel.text = [NSString stringWithFormat:@"%@", routeStep.instructions];
            }

                cell.transportModeImageView.image = [UIImage imageNamed:@"Walking"];
                cell.backgroundColor = [UIColor divvyColor];
                cell.stepLabel.textColor = [UIColor whiteColor];
                cell.distanceLabel.textColor = [UIColor whiteColor];
            return cell;
        }

    // Tableview cells with cycling directions.
        else if (indexPath.section == 4)
        {
            RouteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"routecell"];
            MKRouteStep *routeStep = [self.bikerouteSteps objectAtIndex:indexPath.row];

            if ([routeStep isEqual:[self.bikerouteSteps firstObject]]) {
                cell.distanceLabel.text = @"";
            }
            else {
                CGFloat distance = routeStep.distance * 0.000621371;
                cell.distanceLabel.text = [NSString stringWithFormat:@"Distance\n%.02f mi.", distance];
            }
            // Last element in a routeSteps array says "The destination". I want "The destination" to be replaced by "Divvy Station"
            if ([routeStep isEqual:[self.bikerouteSteps lastObject]]) {

                // Find the instructions string
                NSString *instructions = [[self.walkrouteSteps1 lastObject] instructions];

                // Replace upper case "The destination"
                NSString *instructionsNew = [instructions stringByReplacingOccurrencesOfString:@"The destination" withString:@"Divvy Station"];

                // Replace lower case "the destination"
                NSString *instructionsNew2 = [instructionsNew stringByReplacingOccurrencesOfString:@"the destination" withString:@"Divvy Station"];

                // Set cell steplabel text
                cell.stepLabel.text = [NSString stringWithFormat:@"%@", instructionsNew2];
            }
            else {
                cell.stepLabel.text = [NSString stringWithFormat:@"%@", routeStep.instructions];
            }
                cell.transportModeImageView.image = [UIImage imageNamed:@"bicycle"];
                cell.backgroundColor = [UIColor divvyColor];
                cell.stepLabel.textColor = [UIColor whiteColor];
                cell.distanceLabel.textColor = [UIColor whiteColor];
            return cell;
        }

    // Tableview cells with walking directions for the last leg of the trip.
        else {
            RouteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"routecell"];
            MKRouteStep *routeStep = [self.walkrouteSteps2 objectAtIndex:indexPath.row];

            if ([routeStep isEqual:[self.walkrouteSteps2 firstObject]]) {
                cell.distanceLabel.text = @"";
            }
            else {
                CGFloat distance = routeStep.distance * 0.000621371;
                cell.distanceLabel.text = [NSString stringWithFormat:@"Distance\n%.02f mi.", distance];
            }
                cell.stepLabel.text = [NSString stringWithFormat:@"%@", routeStep.instructions];

                cell.transportModeImageView.image = [UIImage imageNamed:@"Walking"];
                cell.backgroundColor = [UIColor divvyColor];
                cell.stepLabel.textColor = [UIColor whiteColor];
                cell.distanceLabel.textColor = [UIColor whiteColor];
            return cell;
        }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 120.0f;
    }
    else if (indexPath.section == 1) {
        return 90.0f;
    }
    else if (indexPath.section == 2) {
        return 90.0f;
    }
    else {
        return 45.0f;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
        return 0.0f;
}


#pragma mark - mapview methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:MKUserLocation.class]) {
        return nil;
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
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    [geocoder reverseGeocodeLocation:self.userLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark *placemark in placemarks) {
            self.userLocationString = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
            NSLog(@"User Location: %@", self.userLocationString);

            if (self.currentLocationButtonPressed) {
                self.fromTextFieldOutlet.text = self.userLocationString;
                self.currentLocationButtonPressed = NO;
            }
        }
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
        self.currentLocationButtonOutlet.enabled = YES;
    }];
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
}

-(void)setStyle
{
    //Segmented control
    self.segmentedControl.backgroundColor = [UIColor divvyColor];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    self.segmentedControl.layer.borderColor = [[UIColor divvyColor] CGColor];
    self.segmentedControl.layer.borderWidth = 1.0f;
    self.segmentedControl.layer.cornerRadius = 5.0f;
    self.segmentedControl.alpha = .8f;

    // Activity indicator
    self.activityIndicator.color = [UIColor divvyColor];

    //Tableview
    self.tableView.separatorColor = [UIColor divvyColor];

    //Cancel button
    [self.cancelButtonOutlet setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButtonOutlet setBackgroundColor:[UIColor divvyColor]];
    self.cancelButtonOutlet.layer.cornerRadius = 5.0f;
    self.cancelButtonOutlet.layer.borderWidth = 1.0f;
    self.cancelButtonOutlet.layer.borderColor = [[UIColor whiteColor] CGColor];
    [self.cancelButtonOutlet.titleLabel setTextAlignment:NSTextAlignmentCenter];

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

    // To search bar
    self.destinationTextFieldOutlet.layer.cornerRadius = 5.0f;
    [self.destinationTextFieldOutlet setTextColor:[UIColor divvyColor]];

    // Background view
    self.view.backgroundColor = [UIColor divvyColor];
    self.tableViewBlockerView.backgroundColor = [UIColor divvyColor];
}


@end