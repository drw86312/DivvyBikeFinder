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
#import "DestinationAnnotation.h"

@interface SearchViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property CLLocation *userLocation;
@property CLLocationManager *locationManager;
@property MKPlacemark *originPlacemark;
@property MKPlacemark *destinationPlacemark;
@property NSArray *stationsNearOrigin;
@property NSArray *stationsNearDestination;
@property NSString *userLocationString;
@property NSString *userDestinationString;
@property NSString *distanceToDestinationString;
@property NSString *travelTimeString;
@property MKDirectionsRequest *directionRequest;
@property MKPolyline *routeOverlay;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *currentLocationButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *cancelButtonOutlet;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *fromTextFieldOutlet;
@property (weak, nonatomic) IBOutlet UITextField *destinationTextFieldOutlet;
@property BOOL currentLocButtonSelected;

@end

@implementation SearchViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.destinationTextFieldOutlet.delegate = self;
    self.fromTextFieldOutlet.delegate = self;
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager startUpdatingLocation];
    self.locationManager.delegate = self;
    self.mapView.hidden = NO;
    self.tableView.hidden = YES;
    self.currentLocButtonSelected = NO;

    [self.currentLocationButtonOutlet.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.cancelButtonOutlet.titleLabel setTextAlignment:NSTextAlignmentCenter];

    [self setStyle];
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
            self.mapView.showsUserLocation = YES;
            [self.mapView setRegion:region animated:YES];
            break;
        }
    }
}

#pragma mark - IBActions

- (IBAction)onCancelButtonPressed:(id)sender
{
    self.userDestinationString = nil;
    self.fromTextFieldOutlet.text = nil;
    self.destinationTextFieldOutlet.text = nil;
    self.currentLocButtonSelected = NO;

    [self.fromTextFieldOutlet endEditing:YES];
    [self.destinationTextFieldOutlet endEditing:YES];
}

- (IBAction)onCurrentLocationButtonPressed:(id)sender
{
    self.fromTextFieldOutlet.text = self.userLocationString;
    self.currentLocButtonSelected = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self.mapView removeAnnotations:self.mapView.annotations];

    self.userDestinationString = self.destinationTextFieldOutlet.text;
    self.userLocationString = self.fromTextFieldOutlet.text;

    [self.destinationTextFieldOutlet endEditing:YES];
    [self.fromTextFieldOutlet endEditing:YES];

    self.destinationTextFieldOutlet.text = nil;
    self.fromTextFieldOutlet.text = nil;
    
    [self getDestinationFromName];

    return YES;
}

#pragma mark - Search-related methods

-(void)getDestinationFromName
{
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = self.userDestinationString;
    request.region = MKCoordinateRegionMake(self.userLocation.coordinate, MKCoordinateSpanMake(.3, .3));
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];

    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        NSArray *mapItems = response.mapItems;
        if (mapItems.count > 0) {
            NSLog(@"Name successfully found");
            MKMapItem *mapItem = [mapItems firstObject];
            self.destinationPlacemark = mapItem.placemark;

            CLLocation *destinationLocation = [[CLLocation alloc] initWithLatitude:self.destinationPlacemark.coordinate.latitude longitude:self.destinationPlacemark.coordinate.longitude];
            CGFloat distanceToDestination = [destinationLocation distanceFromLocation:self.userLocation];

            [self findDivvyStations:destinationLocation];

            DestinationAnnotation *destinationAnnotation = [[DestinationAnnotation alloc] init];
            destinationAnnotation.coordinate = mapItem.placemark.coordinate;
            destinationAnnotation.title = mapItem.name;
            destinationAnnotation.subtitle = [NSString stringWithFormat:@"Distance: %.02f", distanceToDestination * 0.000621371];

            [self.mapView addAnnotation:destinationAnnotation];
            [self redrawMapViewWithCurrentLocation:self.userLocation.coordinate andDestination:mapItem.placemark.coordinate];
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
            NSLog(@"Address successfully found");
            self.destinationPlacemark = [placemarks firstObject];

            CLLocation *destinationLocation = [[CLLocation alloc] initWithLatitude:self.destinationPlacemark.coordinate.latitude longitude:self.destinationPlacemark.coordinate.longitude];
            CGFloat distanceToDestination = [destinationLocation distanceFromLocation:self.userLocation];

            [self findDivvyStations:destinationLocation];

            DestinationAnnotation *destinationAnnotation = [[DestinationAnnotation alloc] init];
            destinationAnnotation.coordinate = self.destinationPlacemark.coordinate;
            destinationAnnotation.title = self.destinationPlacemark.name;
            destinationAnnotation.subtitle = [NSString stringWithFormat:@"Distance: %.02f", distanceToDestination * 0.000621371];

            [self.mapView addAnnotation:destinationAnnotation];
            [self redrawMapViewWithCurrentLocation:self.userLocation.coordinate andDestination:destinationLocation.coordinate];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:[NSString stringWithFormat:@"No results found matching %@", self.userDestinationString] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
}

-(void)findDivvyStations:(CLLocation *)destinationLocation
{
    // Find three nearest Divvy Stations to user, provided they have available bikes, and add to stationsNearOriginArray.
    NSInteger counter = 0;
    NSMutableArray *tempArray = [NSMutableArray new];
    while (counter < 1) {
        DivvyStation *divvyStation = [self.divvyStations objectAtIndex:counter];
        if (divvyStation.availableBikes > 0) {
            [tempArray addObject:divvyStation];

            DivvyBikeAnnotation *divvyBikesPin = [[DivvyBikeAnnotation alloc] init];
            divvyBikesPin.coordinate = divvyStation.coordinate;
            [self.mapView addAnnotation:divvyBikesPin];
        }
        counter += 1;
    }
    self.stationsNearOrigin = [NSArray arrayWithArray:tempArray];

    // Find three nearest Divvy Stations to the user's destination, provided they have available docks, and add to stationsNearDestinationArray.

    // Assign the distanceFromDestination property to each station in the divvyStations array.
    NSMutableArray *tempArray2 = [NSMutableArray new];
    for (DivvyStation *divvyStation in self.divvyStations) {
        CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:divvyStation.latitude.floatValue longitude:divvyStation.longitude.floatValue];
        divvyStation.distanceFromDestination = [destinationLocation distanceFromLocation:stationLocation];
        [tempArray2 addObject:divvyStation];
    }

    // Sort the temporary array by distance to destination
    NSSortDescriptor *distanceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromDestination" ascending:YES];
    NSArray *sortDescriptors = @[distanceDescriptor];
    NSArray *divvyStationsArray = [tempArray2 sortedArrayUsingDescriptors:sortDescriptors];

    // Find first three stations closest to the user's destination, provided docks are available.
    NSInteger counter2 = 0;
    NSMutableArray *tempArray3 = [NSMutableArray new];
    while (counter2 < 1) {
        DivvyStation *divvyStation = [divvyStationsArray objectAtIndex:counter2];
        if (divvyStation.availableDocks > 0) {
            [tempArray3 addObject:divvyStation];

            DivvyBikeAnnotation *divvyBikesPin = [[DivvyBikeAnnotation alloc] init];
            divvyBikesPin.coordinate = divvyStation.coordinate;
            [self.mapView addAnnotation:divvyBikesPin];
        }
        counter2 += 1;
    }
    self.stationsNearDestination = [NSArray arrayWithArray:tempArray3];


    if (self.stationsNearDestination.count > 0 && self.stationsNearOrigin.count > 0) {
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
    MKPlacemark *originPlacemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake([[[self.stationsNearOrigin firstObject] latitude] floatValue], [[[self.stationsNearOrigin firstObject] longitude] floatValue]) addressDictionary:nil];
    MKMapItem *originMapItem = [[MKMapItem alloc] initWithPlacemark:originPlacemark];

    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake([[[self.stationsNearDestination firstObject] latitude] floatValue], [[[self.stationsNearDestination firstObject] longitude] floatValue]) addressDictionary:nil];
    MKMapItem *destinationMapItem = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];

    self.directionRequest = [MKDirectionsRequest new];
    self.directionRequest.source = originMapItem;
    self.directionRequest.destination = destinationMapItem;
    self.directionRequest.transportType =MKDirectionsTransportTypeWalking;

    MKDirections *directions = [[MKDirections alloc] initWithRequest:self.directionRequest];

    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {

        NSArray *routeItems = response.routes;
        MKRoute *route = [routeItems firstObject];

        // Convert expected travel time interval to minutes (rounded) and assume riding a bike is about 3 times faster than walking (approx. 9.3 MPH bike riding speed assumption)
        NSTimeInterval interval = route.expectedTravelTime;
        CGFloat timeIntervalInMinutes = (interval/60)/3;
        NSInteger timeIntervalRounded = timeIntervalInMinutes;
        self.travelTimeString = [NSString stringWithFormat:@"%ld min", (long)timeIntervalRounded];

        NSArray *routeSteps = route.steps;

        NSInteger step = 1;
        CGFloat distance = 0;
        for (MKRouteStep *routeStep in routeSteps) {
            distance += routeStep.distance;
//            NSLog(@"Step%ld: %@, distance: %@", step, routeStep.instructions, @(routeStep.distance));
            step += 1;
        }
        self.distanceToDestinationString = [NSString stringWithFormat:@"%.01f mi.", distance * 0.000621371];

        [self plotRouteOnMap:route];
        [self.tableView reloadData];
    }];
}


#pragma mark - Tableview methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
        return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Your Trip";
    }
    else if (section == 1)
    {
        return @"Station Nearest You";
    }
    else {
        return @"Station Nearest To Destination";
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
        }
    else if (section == 1) {
        return self.stationsNearOrigin.count;
        }
    else if (section == 2)
        {
        return self.stationsNearDestination.count;
        }
    else {
        return 0;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        if (indexPath.section == 0) {
            TripTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tripcell"];
            cell.tripLabel.text = [NSString stringWithFormat:@"From: %@\nTo: %@", self.userLocationString, self.userDestinationString];
            cell.distanceLabel.text = [NSString stringWithFormat:@"Distance: %@", self.distanceToDestinationString];
            cell.etaLabel.text = [NSString stringWithFormat:@"Travel Time: %@", self.travelTimeString];

            cell.backgroundColor = [UIColor blackColor];
            cell.tripLabel.textColor = [UIColor whiteColor];
            cell.distanceLabel.textColor = [UIColor whiteColor];
            cell.etaLabel.textColor = [UIColor whiteColor];

            return cell;
        }

        else if (indexPath.section == 1) {
            BikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            DivvyStation *divvyStation = [self.stationsNearOrigin objectAtIndex:indexPath.row];
            cell.backgroundColor = [UIColor blackColor];

            cell.stationLabel.text = divvyStation.stationName;

            cell.bikesLabel.text = [NSString stringWithFormat:@"Bikes\n%@", divvyStation.availableBikes.description];

            cell.docksLabel.text = [NSString stringWithFormat:@"Docks\n%@", divvyStation.availableDocks.description];

            NSString *milesFromUser = [NSString stringWithFormat:@"%.02f miles", divvyStation.distanceFromUser * 0.000621371];
            cell.distanceLabel.text = milesFromUser;

            cell.stationLabel.textColor = [UIColor whiteColor];
            cell.distanceLabel.textColor = [UIColor whiteColor];
            cell.bikesLabel.textColor = [UIColor whiteColor];
            cell.docksLabel.textColor = [UIColor whiteColor];
            return cell;
        }
        else {
            BikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            DivvyStation *divvyStation = [self.stationsNearDestination objectAtIndex:indexPath.row];

            cell.backgroundColor = [UIColor blackColor];

            cell.stationLabel.text = divvyStation.stationName;

            cell.bikesLabel.text = [NSString stringWithFormat:@"Bikes\n%@", divvyStation.availableBikes.description];

            cell.docksLabel.text = [NSString stringWithFormat:@"Docks\n%@", divvyStation.availableDocks.description];

            NSString *milesFromUser = [NSString stringWithFormat:@"%.02f miles from %@", divvyStation.distanceFromDestination * 0.000621371, self.userDestinationString];
            cell.distanceLabel.text = milesFromUser;

            cell.stationLabel.textColor = [UIColor whiteColor];
            cell.distanceLabel.textColor = [UIColor whiteColor];
            cell.bikesLabel.textColor = [UIColor whiteColor];
            cell.docksLabel.textColor = [UIColor whiteColor];
            return cell;
        }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 80.0f;
    }
    else {
        return 60.0f;
    }
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
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor blueColor];
    renderer.lineWidth = 4.0;
    return  renderer;
}

-(void)plotRouteOnMap:(MKRoute *)route
{
    if(self.routeOverlay) {
        [self.mapView removeOverlay:self.routeOverlay];
    }

    // Update the ivar
    self.routeOverlay = route.polyline;

    // Add it to the map
    [self.mapView addOverlay:self.routeOverlay];
}

#pragma mark - Segmented Control methods

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

#pragma mark - helper methods

- (void)getUserLocationString
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    [geocoder reverseGeocodeLocation:self.userLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark *placemark in placemarks) {
            self.userLocationString = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
        }
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
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.7;
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.7;

    region = [self.mapView regionThatFits:region];
    [self.mapView setRegion:region animated:YES];
}

-(void)setStyle
{
    //Segmented control
    self.segmentedControl.backgroundColor = [UIColor blueColor];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    self.segmentedControl.layer.borderColor = [[UIColor blueColor] CGColor];
    self.segmentedControl.layer.borderWidth = 1.0f;
    self.segmentedControl.layer.cornerRadius = 5.0f;
    self.segmentedControl.alpha = .8f;
}


@end
