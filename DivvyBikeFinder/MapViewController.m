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
#import "UIFont+DesignFonts.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

@interface MapViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSTimer *timer;
@property CLLocationManager *locationManager;
@property CLLocation *userLocation;
@property NSArray *divvyStations;
@property DivvyStation *selectedStation;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSString *userLocationString;
@property NSString *userDestinationString;
@property UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButtonOutlet;
@property UIImageView *mapDivvyImage;
@property UITapGestureRecognizer *tapToCloseMapContainer;
@property UIView *mapContainerView;

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
    self.refreshButtonOutlet.enabled = NO;

    [self setStyle];

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    [self createMapContainerView];
    [self createMapDivvyImageView];
}

#pragma mark - Location manager methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"Locations count: %lu", (unsigned long)locations.count);
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000) {
            [self.locationManager stopUpdatingLocation];

            // Assign userlocation IVar
            self.userLocation = location;
            [self getJSON];

            // Instantiate chicago location and assign the "distance from chicago" variable
            CLLocation *chicago = [[CLLocation alloc] initWithLatitude:41.891813 longitude:-87.647343];
            CGFloat userDistanceFromChicago = [chicago distanceFromLocation:self.userLocation];

            // If user is too far from Chicago, map will default to the Chicago area.
            // 80,466 meters is 50 miles, approximately.
            if (userDistanceFromChicago > 80466) {
                CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(chicago.coordinate.latitude, chicago.coordinate.longitude);
                MKCoordinateSpan span = MKCoordinateSpanMake(.1, .1);
                MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
                self.mapView.showsUserLocation = YES;
                [self.mapView setRegion:region animated:YES];
                break;
            }
            // If user is in Chicago, draw map around their location.
            else {
                CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude);
                MKCoordinateSpan span = MKCoordinateSpanMake(.03, .03);
                MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
                self.mapView.showsUserLocation = YES;
                [self.mapView setRegion:region animated:YES];
                break;
            }
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
             self.refreshButtonOutlet.enabled = YES;
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

                 // Assign the distance from user property, if there is a user location.
                 if (self.userLocation) {
                     CLLocation *stationLocation = [[CLLocation alloc] initWithLatitude:divvyStation.latitude.floatValue longitude:divvyStation.longitude.floatValue];
                     divvyStation.distanceFromUser = [stationLocation distanceFromLocation:self.userLocation];
                    }

                 // Add the divvyStation to the temporary array.
                 [tempArray addObject:divvyStation];
                }

             // Sort the temporary array by distance from the user's location.
            NSSortDescriptor *distanceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromUser" ascending:YES];
             NSArray *sortDescriptors = @[distanceDescriptor];
             NSArray *divvyStationsArray = [NSArray arrayWithArray:tempArray];

             // Assign the sorted array to the divvyStations ivar array.
             self.divvyStations = [divvyStationsArray sortedArrayUsingDescriptors:sortDescriptors];

             // Find the station annotation scaler value
                CGFloat totalDocks = 0;
                CGFloat totalStations = self.divvyStations.count;
                for (DivvyStation *divvyStation in self.divvyStations) {
                    CGFloat divvyStationDocks = divvyStation.availableBikes.floatValue + divvyStation.availableDocks.floatValue;
                    totalDocks += divvyStationDocks;
                    }
                CGFloat averageStationSize = totalDocks/totalStations;
                for (DivvyStation *divvyStation in self.divvyStations) {
                    divvyStation.annotationSizeScaler = (divvyStation.availableBikes.floatValue + divvyStation.availableDocks.floatValue)/averageStationSize;
                }

             // Call helper method to set station colors, reload the tableview and call method to create map annotations.
             [self setStationColors:self.divvyStations];
             [self createMapAnnotations];
             [self.tableView reloadData];
            }

         // After JSON data has returned stop the activity indicator and enable buttons.
         self.activityIndicator.hidden = YES;
         [self.activityIndicator stopAnimating];
         self.refreshButtonOutlet.enabled = YES;
    }];
}

-(void)createMapAnnotations
{
    for (DivvyStation *divvyStation in self.divvyStations) {
        if (divvyStation.availableBikes.intValue < 1) {
            NoBikesAnnotation *annotation = [[NoBikesAnnotation alloc] init];
            annotation.title = divvyStation.stationName;
            annotation.subtitle = [NSString stringWithFormat:@"%.01f miles away  %@ Bikes  %@ Docks", divvyStation.distanceFromUser * 0.000621371, divvyStation.availableBikes, divvyStation.availableDocks];
            annotation.coordinate = divvyStation.coordinate;
            annotation.imageName = @"No-Bikes";
            annotation.backgroundColor = [UIColor redColor];
            annotation.sizeScaler = divvyStation.annotationSizeScaler;
            [self.mapView addAnnotation:annotation];
        }
        else if (divvyStation.availableDocks.intValue < 1) {
            NoDocksAnnotation *annotation = [[NoDocksAnnotation alloc] init];
            annotation.title = divvyStation.stationName;
            annotation.subtitle = [NSString stringWithFormat:@"%.01f miles away  %@ Bikes  %@ Docks", divvyStation.distanceFromUser * 0.000621371, divvyStation.availableBikes, divvyStation.availableDocks];
            annotation.coordinate = divvyStation.coordinate;
            annotation.imageName = @"No-Docks";
            annotation.backgroundColor = [UIColor greenColor];
            annotation.sizeScaler = divvyStation.annotationSizeScaler;
            [self.mapView addAnnotation:annotation];
        }
        else {
            DivvyBikeAnnotation *annotation = [[DivvyBikeAnnotation alloc] init];
            annotation.title = divvyStation.stationName;
            annotation.subtitle = [NSString stringWithFormat:@"%.01f miles away  %@ Bikes  %@ Docks", divvyStation.distanceFromUser * 0.000621371, divvyStation.availableBikes, divvyStation.availableDocks];
            annotation.coordinate = divvyStation.coordinate;
            annotation.imageName = @"Divvy";
            annotation.backgroundColor = divvyStation.bikesColor;
            annotation.sizeScaler = divvyStation.annotationSizeScaler;
            [self.mapView addAnnotation:annotation];
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:MKUserLocation.class]) {
        return nil;
    }

    else if ([annotation isKindOfClass:[NoBikesAnnotation class]]) {
        NoBikesAnnotation *noBikesAnnotation = annotation;
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

            annotationView.image = [UIImage imageNamed:noBikesAnnotation.imageName];
            annotationView.frame = CGRectMake(0, 0, (20 + (7.0f * noBikesAnnotation.sizeScaler)), (20 + (7.0f * noBikesAnnotation.sizeScaler)));
            annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
            annotationView.backgroundColor = noBikesAnnotation.backgroundColor;

        return annotationView;
        }

    else if ([annotation isKindOfClass:[NoDocksAnnotation class]]) {
        NoDocksAnnotation *noDocksAnnotation = annotation;
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

        annotationView.image = [UIImage imageNamed:noDocksAnnotation.imageName];
        annotationView.frame = CGRectMake(0, 0, (20 + (6.0f * noDocksAnnotation.sizeScaler)), (20 + (7.0f * noDocksAnnotation.sizeScaler)));
        annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
        annotationView.backgroundColor = noDocksAnnotation.backgroundColor;
        return annotationView;
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
            annotationView.frame = CGRectMake(0, 0, (20 + (7.0f * divvyAnnotation.sizeScaler)), (20 + (7.0f * divvyAnnotation.sizeScaler)));
            annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
            annotationView.backgroundColor = divvyAnnotation.backgroundColor;

        return annotationView;
        }

    else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"segue" sender:self];
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKPinAnnotationView *)view
{
    for (DivvyStation *station in self.divvyStations)
    {
        if ([view.annotation.title isEqualToString:station.stationName]) {
            self.selectedStation = station;
        }
    }
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
        cell.stationLabel.font = [UIFont mediumFont];

        cell.bikesLabel.text = [NSString stringWithFormat:@"Bikes\n%@", divvyStation.availableBikes.description];
        cell.bikesLabel.backgroundColor = divvyStation.bikesColor;
        cell.bikesLabel.textColor = [UIColor blackColor];
        cell.bikesLabel.layer.borderWidth = 1.0f;
        cell.bikesLabel.layer.borderColor = [[UIColor blackColor] CGColor];
        cell.bikesLabel.font = [UIFont mediumFont];

        cell.docksLabel.text = [NSString stringWithFormat:@"Docks\n%@", divvyStation.availableDocks.description];
        cell.docksLabel.textColor = [UIColor blackColor];
        cell.docksLabel.backgroundColor = divvyStation.docksColor;
        cell.docksLabel.layer.borderWidth = 1.0f;
        cell.docksLabel.layer.borderColor = [[UIColor blackColor] CGColor];
        cell.docksLabel.font = [UIFont mediumFont];

        NSString *milesFromUser = [NSString stringWithFormat:@"%.02f miles", divvyStation.distanceFromUser * 0.000621371];
        cell.distanceLabel.text = milesFromUser;
        cell.distanceLabel.font = [UIFont smallFont];
        return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedStation = [self.divvyStations objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"segue" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DivvyStation *station = self.selectedStation;
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
        self.mapDivvyImage.hidden = NO;
        self.tableView.hidden = YES;
        self.mapContainerView.hidden = NO;
        self.segmentedControl.layer.borderColor = [[UIColor divvyColor] CGColor];
    }
    else
    {
        self.mapView.hidden = YES;
        self.mapDivvyImage.hidden = YES;
        self.tableView.hidden = NO;
        self.mapContainerView.hidden = YES;
        self.segmentedControl.layer.borderColor = [[UIColor whiteColor] CGColor];
    }
}
- (IBAction)onSegmentControlToggle:(id)sender
{
    [self segmentChanged:sender];
}

#pragma mark -ContainerView methods
-(void)createMapContainerView
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat containerViewHeight = 40.0f;
    CGFloat containerViewWidth = 40.0f;
    CGFloat horizontalOffset = self.view.frame.size.width - containerViewWidth -10.0f;
    CGFloat verticalOffset = self.view.frame.size.height -tabBarHeight - containerViewHeight -10.0f;

    // Create view to hold the map information vies.
    self.mapContainerView = [[UIView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, containerViewWidth, containerViewHeight)];
    [self.view addSubview:self.mapContainerView];

    // Add the "i" info button to mapcontainer view.
    UIButton *expandButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.mapContainerView.frame.size.width, self.mapContainerView.frame.size.height)];
    [expandButton setBackgroundColor:[UIColor divvyColor]];
    [expandButton setBackgroundImage:[UIImage imageNamed:@"info"] forState:UIControlStateNormal];
    expandButton.alpha = 0.8f;
    expandButton.layer.cornerRadius = containerViewHeight/2;
    [expandButton addTarget:self
                action:@selector(openContainer:)
      forControlEvents:UIControlEventTouchUpInside];
    [self.mapContainerView addSubview:expandButton];
}

-(void)openContainer:(id)sender
{
    // Hide the divvy logo image and disable the segmented control
    self.segmentedControl.enabled = NO;
    self.mapDivvyImage.hidden = YES;

    // Clear containerview
    [self removeMapContainerSubviews];
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Resize containerview
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat containerViewHeight = 60.0f;
    CGFloat containerViewWidth = self.view.frame.size.width;
    CGFloat horizontalOffset = self.view.frame.origin.x;
    CGFloat verticalOffset = self.view.frame.size.height - tabBarHeight - containerViewHeight;

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];

    self.mapContainerView.frame = CGRectMake(horizontalOffset, verticalOffset, containerViewWidth, containerViewHeight);

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create gradient view and add the gradient to it
    CGFloat gradientViewHeight = self.mapContainerView.frame.size.height;
    CGFloat gradientViewWidth = self.mapContainerView.frame.size.width;
    horizontalOffset = 0.0f;
    verticalOffset = 0.0f;
    UIView *gradientView = [[UIView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, gradientViewWidth, gradientViewHeight)];
    [self.mapContainerView addSubview:gradientView];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = gradientView.bounds;
    [gradient setStartPoint:CGPointMake(0.0, 0.5)];
    [gradient setEndPoint:CGPointMake(1.0, 0.5)];
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor greenColor] CGColor], (id)[[UIColor yellowColor] CGColor], (id)[[UIColor redColor] CGColor], nil];
    [gradientView.layer insertSublayer:gradient atIndex:0];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Set view size parameters
    CGFloat spacing = 5.0f;
    CGFloat labelWidth = 70.0f;
    CGFloat labelHeight = 10.0f;
    CGFloat imageViewWidth = 30.0;
    CGFloat imageViewHeight = 30.0;
    NSInteger fontSize = 10;
    UIColor *textColor = [UIColor blackColor];

    // Create label for "No Docks"

    horizontalOffset += spacing;
    verticalOffset += spacing;
    UILabel *noDocksLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    noDocksLabel.text = @"No Docks";
    noDocksLabel.textColor = textColor;
    noDocksLabel.textAlignment = NSTextAlignmentCenter;
    [noDocksLabel setFont:[UIFont fontWithName:@"Helvetica" size:fontSize]];
    [self.mapContainerView addSubview:noDocksLabel];

    verticalOffset += noDocksLabel.frame.size.height;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create ImageView for "No Docks"
    horizontalOffset = (labelWidth/2 + spacing) - (imageViewWidth/2);

    UIImageView *noDocksImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    noDocksImageView.image = [UIImage imageNamed:@"No-Docks"];
    [self.mapContainerView addSubview:noDocksImageView];

    verticalOffset += noDocksImageView.frame.size.height;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create label for "Station Full"
    horizontalOffset = spacing;

    UILabel *stationFullLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    stationFullLabel.text = @"Station Full";
    stationFullLabel.textColor = textColor;
    stationFullLabel.textAlignment = NSTextAlignmentCenter;
    [stationFullLabel setFont:[UIFont fontWithName:@"Helvetica" size:fontSize]];
    [self.mapContainerView addSubview:stationFullLabel];

    // Add tap that will close the mapContainer view, when the user taps anywhere on the view.
    self.tapToCloseMapContainer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeContainer:)];
    [self.view addGestureRecognizer:self.tapToCloseMapContainer];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Add "More bikes" label
    horizontalOffset = (self.mapContainerView.frame.size.width/2) - labelWidth - spacing;
    verticalOffset = spacing;

    UILabel *moreBikesLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    moreBikesLabel.text = @"More Bikes";
    moreBikesLabel.textColor = textColor;
    moreBikesLabel.textAlignment = NSTextAlignmentCenter;
    [moreBikesLabel setFont:[UIFont fontWithName:@"Helvetica" size:fontSize]];
    [self.mapContainerView addSubview:moreBikesLabel];

    verticalOffset += moreBikesLabel.frame.size.height + spacing;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create Left arrow imageview
    horizontalOffset += (labelWidth/2) - (imageViewWidth/2);

    UIImageView *leftArrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    leftArrowImageView.image = [UIImage imageNamed:@"leftarrow"];
    [self.mapContainerView addSubview:leftArrowImageView];
    verticalOffset += noDocksImageView.frame.size.height;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Add Fewer bikes label
    horizontalOffset = (self.mapContainerView.frame.size.width/2) + spacing;
    verticalOffset = spacing;

    UILabel *fewerBikesLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    fewerBikesLabel.text = @"Fewer Bikes";
    fewerBikesLabel.textColor = textColor;
    fewerBikesLabel.textAlignment = NSTextAlignmentCenter;
    [fewerBikesLabel setFont:[UIFont fontWithName:@"Helvetica" size:fontSize]];
    [self.mapContainerView addSubview:fewerBikesLabel];

    verticalOffset += fewerBikesLabel.frame.size.height + spacing;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create Right arrow imageview
    horizontalOffset += (labelWidth/2) - (imageViewWidth/2);

    UIImageView *rightArrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    rightArrowImageView.image = [UIImage imageNamed:@"rightarrow"];
    [self.mapContainerView addSubview:rightArrowImageView];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    // Create label for "No Bikes"
    verticalOffset = spacing;
    horizontalOffset = self.mapContainerView.frame.size.width - spacing - labelWidth;

    UILabel *noBikesLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    noBikesLabel.text = @"No Bikes";
    noBikesLabel.textColor = textColor;
    noBikesLabel.textAlignment = NSTextAlignmentCenter;
    [noBikesLabel setFont:[UIFont fontWithName:@"Helvetica" size:fontSize]];
    [self.mapContainerView addSubview:noBikesLabel];

    verticalOffset += noBikesLabel.frame.size.height;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create ImageView for "No Bikes"
    horizontalOffset += (labelWidth/2) - (imageViewWidth/2);

    UIImageView *noBikesImageView = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    noBikesImageView.image = [UIImage imageNamed:@"No-Bikes"];
    [self.mapContainerView addSubview:noBikesImageView];

    verticalOffset += noBikesImageView.frame.size.height;
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create label for "Station Empty"
    horizontalOffset = self.mapContainerView.frame.size.width - spacing - labelWidth;

    UILabel *stationEmptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    stationEmptyLabel.text = @"Station Empty";
    stationEmptyLabel.textColor = textColor;
    stationEmptyLabel.textAlignment = NSTextAlignmentCenter;
    [stationEmptyLabel setFont:[UIFont fontWithName:@"Helvetica" size:fontSize]];
    [self.mapContainerView addSubview:stationEmptyLabel];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    [UIView commitAnimations];

    // Add tap that will close the mapContainer view, when the user taps anywhere on the view.
    self.tapToCloseMapContainer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeContainer:)];
    [self.view addGestureRecognizer:self.tapToCloseMapContainer];
}

-(void)closeContainer:(id)sender
{
    // Remove tap to close gesture recognizer
    for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
        [self.view removeGestureRecognizer:recognizer];
    }
    self.tapToCloseMapContainer = nil;

    // Show the divvy logo image and enable the segmented control
    self.mapDivvyImage.hidden = NO;
    self.segmentedControl.enabled = YES;

    [self removeMapContainerSubviews];

    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat containerViewHeight = 40.0f;
    CGFloat containerViewWidth = 40.0f;
    CGFloat horizontalOffset = self.view.frame.size.width - containerViewWidth -10.0f;
    CGFloat verticalOffset = self.view.frame.size.height - tabBarHeight - containerViewHeight -10.0f;

    // Resize map containerview
    self.mapContainerView.frame = CGRectMake(horizontalOffset, verticalOffset, containerViewWidth, containerViewHeight);

    // Add the "i" info button to mapcontainer view.
    UIButton *expandButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.mapContainerView.frame.size.width, self.mapContainerView.frame.size.height)];
    [expandButton setBackgroundColor:[UIColor divvyColor]];
    [expandButton setBackgroundImage:[UIImage imageNamed:@"info"] forState:UIControlStateNormal];
    expandButton.alpha = 0.8f;
    expandButton.layer.cornerRadius = containerViewHeight/2;
    [expandButton addTarget:self
                     action:@selector(openContainer:)
           forControlEvents:UIControlEventTouchUpInside];
    [self.mapContainerView addSubview:expandButton];
}

-(void)createMapDivvyImageView
{
    // Create Yelp Imageview
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat imageViewHeight = 40.0f;
    CGFloat imageViewWidth = 40.0f;
    CGFloat verticalOffset = self.view.frame.size.height - tabBarHeight - imageViewHeight -10.0f;
    CGFloat horizontalOffset = self.view.frame.origin.x + 10.0f;

    self.mapDivvyImage = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    self.mapDivvyImage.hidden = NO;
    self.mapDivvyImage.image = [UIImage imageNamed:@"DivvyLogo"];
    self.mapDivvyImage.alpha = .8f;
    [self.view addSubview:self.mapDivvyImage];
}

-(void)setStationColors:(NSArray *)stationsArray
{
    // Dynamically update the background color from red -> yellow -> green
    // Max RGB value = 255.0, the blue color is not in this spectrum, thus it is always 0.
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

-(void)removeMapContainerSubviews
{
    NSArray *subviews = [self.mapContainerView subviews];

    for (UIButton *button in subviews) {
        [button removeFromSuperview];
    }

    for (UILabel *label in subviews) {
        [label removeFromSuperview];
    }
    for (UIView *view in subviews) {
        [view   removeFromSuperview];
    }
    for (UIImageView *imageView in subviews) {
        [imageView removeFromSuperview];
    }
}

-(void)setStyle
{
    // Set hidden/show initial views
    self.mapView.hidden = NO;
    self.tableView.hidden = YES;

    //Set backgroundview
    self.view.backgroundColor = [UIColor divvyColor];
    self.navigationItem.title = @"Divvy & Conquer";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

    //Segmented control
    self.segmentedControl.backgroundColor = [UIColor divvyColor];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    self.segmentedControl.layer.borderColor = [[UIColor divvyColor] CGColor];
    self.segmentedControl.layer.borderWidth = 1.0f;
    self.segmentedControl.layer.cornerRadius = 5.0f;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont bigFontBold]};
    [self.segmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];

    // Activity indicator
    self.activityIndicator.color = [UIColor divvyColor];

    // Refresh button
    self.refreshButtonOutlet.tintColor = [UIColor divvyColor];

    //Tab bar
    [self.tabBarController.tabBar setSelectedImageTintColor:[UIColor divvyColor]];
}

@end
