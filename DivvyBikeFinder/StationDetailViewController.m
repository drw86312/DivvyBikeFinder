//
//  StationDetailViewController.m
//  DivvyBikeFinder
//
//  Created by David Warner on 7/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "StationDetailViewController.h"
#import "DivvyBikeAnnotation.h"
#import "UIColor+DesignColors.h"
#import "UIFont+DesignFonts.h"
#import "WebviewViewController.h"
#import <MapKit/MapKit.h>
#import "YelpLocation.h"
#import "FoodAnnotation.h"
#import "DrinkAnnotation.h"
#import "ShopAnnotation.h"
#import "MusicAnnotation.h"
#import "SightseeAnnotation.h"
#import "UIImageView+WebCache.h"
#import "YelpTableViewCell.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "TDOAuth.h"

@interface StationDetailViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property CLLocationManager *locationManager;
@property UIView *backgroundView;
@property NSMutableArray *buttonsArray;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *blockerView;
@property UIView *mapContainerView;
@property YelpLocation *selectedYelpLocation;
@property UISegmentedControl *segmentedControl;
@property NSString *searchTerm;
@property NSNumber *sortType;
@property NSString *neighborhood1;
@property NSString *neighborhood2;
@property UILabel *neighborhoodsLabel;
@property NSArray *yelpLocations;
@property NSInteger counter;
@property NSInteger counter2;
@property UIActivityIndicatorView *activityIndicator;
@property UITapGestureRecognizer *tapToOpenMapContainer;
@property UITapGestureRecognizer *tapToCloseMapContainer;
@property UIImageView *mapYelpImage;
@property id request;
@property UIButton *button1;
@property UIButton *button2;
@property UIButton *button3;
@property UIButton *button4;
@property UIButton *button5;
@property BOOL foodSearch;
@property BOOL drinkSearch;
@property BOOL shopSearch;
@property BOOL sightseeSearch;
@property BOOL musicSearch;


@end

@implementation StationDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.locationManager = [[CLLocationManager alloc] init];
//    [self.locationManager startUpdatingLocation];
    self.locationManager.delegate = self;
    [self disableSearchBooleans];
    [self setMapViewandPlacePin];
    [self makeStationDetailView];
    [self findNeighborhoods];

    self.navigationItem.title = self.stationFromSourceVC.stationName;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.tintColor = [UIColor divvyColor];

    self.tableView.separatorColor = [UIColor walkRouteColor];

    self.view.backgroundColor = [UIColor divvyColor];
    self.blockerView.backgroundColor = [UIColor divvyColor];
}

-(void)makeStationDetailView
{
    // Find status and navigation bar heights and set spacing between views
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat backgroundViewHeight = 50.0f;

    // Create a background view to hold station details
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, navBarHeight + statusBarHeight, self.view.frame.size.width, backgroundViewHeight)];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.backgroundView];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Add the station label
    CGFloat verticalOffset = 2.5f;
    CGFloat horizontalOffset = 10.0f;
    CGFloat stationLabelWidth = self.view.frame.size.width - ( 2* horizontalOffset);
    CGFloat stationLabelHeight = 25.0f;

    UILabel *stationLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, stationLabelWidth, stationLabelHeight)];
    stationLabel.text = [NSString stringWithFormat:@"Bikes: %@   Docks: %@", self.stationFromSourceVC.availableBikes, self.stationFromSourceVC.availableDocks];
    stationLabel.textColor = [UIColor whiteColor];
    stationLabel.textAlignment = NSTextAlignmentCenter;
    [stationLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:21]];
    stationLabel.numberOfLines = 0;
    [self.backgroundView addSubview:stationLabel];

    verticalOffset += stationLabel.frame.size.height;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Add the neighborhoods label - must be a property as its text gets set in the findNeighborhoods method.
    CGFloat neighborhoodsLabelWidth = stationLabelWidth;
    CGFloat neighborhoodsLabelHeight = 17.5f;

    self.neighborhoodsLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, neighborhoodsLabelWidth, neighborhoodsLabelHeight)];
    self.neighborhoodsLabel.numberOfLines = 1;
    self.neighborhoodsLabel.textAlignment = NSTextAlignmentCenter;
    self.neighborhoodsLabel.textColor = [UIColor whiteColor];
    [self.neighborhoodsLabel setFont:[UIFont fontWithName:@"Helvetica" size:15]];
    [self.backgroundView addSubview:self.neighborhoodsLabel];

    verticalOffset = verticalOffset + self.neighborhoodsLabel.frame.size.height;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create the activity indicator
    CGFloat indicatorWidth = 50.0f;
    CGFloat indicatorHeight = 50.0f;

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.frame = CGRectMake((self.view.frame.size.width/2) - (indicatorWidth/2), (self.view.frame.size.height/2) - (indicatorHeight/2), indicatorWidth, indicatorHeight);
    self.activityIndicator.color = [UIColor divvyColor];
    self.activityIndicator.hidden = YES;
    [self.view addSubview:self.activityIndicator];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Make buttons
    [self makeExploreButtonsandSegmentedControl];
}

-(void)makeExploreButtonsandSegmentedControl
{
    self.buttonsArray = [NSMutableArray new];

    self.button1 = [[UIButton alloc] init];
    self.button2 = [[UIButton alloc] init];
    self.button3 = [[UIButton alloc] init];
    self.button4 = [[UIButton alloc] init];
    self.button5 = [[UIButton alloc] init];

    _button1.tag = 0;
    _button2.tag = 1;
    _button3.tag = 2;
    _button4.tag = 3;
    _button5.tag = 4;

    [self.buttonsArray addObject:_button1];
    [self.buttonsArray addObject:_button2];
    [self.buttonsArray addObject:_button3];
    [self.buttonsArray addObject:_button4];
    [self.buttonsArray addObject:_button5];

    CGFloat spacing = 10.0f;
    CGFloat verticalOffset = self.backgroundView.frame.origin.y + self.backgroundView.frame.size.height;
    CGFloat horizontalOffset = 10.0f;
    CGFloat buttonWidth = (self.view.frame.size.width - ((self.buttonsArray.count + 1) * spacing))/ self.buttonsArray.count;
    CGFloat buttonHeight = buttonWidth;

    for (UIButton *button in self.buttonsArray) {
        button.frame = CGRectMake(horizontalOffset, verticalOffset, buttonWidth, buttonHeight);
        button.layer.cornerRadius = button.frame.size.width/2;
        button.layer.borderWidth = 1.0f;
        button.layer.borderColor = [[UIColor walkRouteColor] CGColor];
        button.backgroundColor = [UIColor whiteColor];
        [button setTitleColor:[UIColor walkRouteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15.0];

        horizontalOffset += button.frame.size.width + spacing;
        [self.view addSubview:button];
    }

    [_button1 setImage:[UIImage imageNamed:@"foodcolor"] forState:UIControlStateNormal];
    [_button2 setImage:[UIImage imageNamed:@"drinkcolor"] forState:UIControlStateNormal];
    [_button3 setImage:[UIImage imageNamed:@"shopcolor"] forState:UIControlStateNormal];
    [_button4 setImage:[UIImage imageNamed:@"sightseecolor"] forState:UIControlStateNormal];
    [_button5 setImage:[UIImage imageNamed:@"guitarcolor"] forState:UIControlStateNormal];

    [_button1 addTarget:self
               action:@selector(button1Selected:)
     forControlEvents:UIControlEventTouchUpInside];

    [_button2 addTarget:self
                action:@selector(button2Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [_button3 addTarget:self
                action:@selector(button3Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [_button4 addTarget:self
                action:@selector(button4Selected:)
      forControlEvents:UIControlEventTouchUpInside];

    [_button5 addTarget:self
                action:@selector(button5Selected:)
      forControlEvents:UIControlEventTouchUpInside];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create segmented control
    CGFloat segmentedControlHeight = 30.0f;
    CGFloat segmentedControlWidth = 290.0f;
    verticalOffset += _button1.frame.size.height + (spacing + 2);
    horizontalOffset = (self.view.frame.size.width/2) - (segmentedControlWidth/2);

    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Map",@"List"]];
    self.segmentedControl.frame = CGRectMake(horizontalOffset, verticalOffset, segmentedControlWidth, segmentedControlHeight);
    [self.segmentedControl setSelectedSegmentIndex:0];
    [self.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.enabled = NO;
    self.segmentedControl.backgroundColor = [UIColor walkRouteColor];
    self.segmentedControl.tintColor = [UIColor whiteColor];
    self.segmentedControl.layer.borderWidth = 1.0f;
    self.segmentedControl.layer.borderColor = [[UIColor walkRouteColor] CGColor];
    self.segmentedControl.layer.cornerRadius = 5.0f;
    UIFont *font = [UIFont boldSystemFontOfSize:17.0f];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    [self.segmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.view addSubview:self.segmentedControl];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Create Yelp Imageview
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat imageViewHeight = 25.0f;
    CGFloat imageViewWidth = 50.0f;
    verticalOffset = self.view.frame.size.height - tabBarHeight - imageViewHeight -10.0f;
    horizontalOffset = self.view.frame.origin.x + 10.0f;

    self.mapYelpImage = [[UIImageView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, imageViewWidth, imageViewHeight)];
    self.mapYelpImage.hidden = NO;
    self.mapYelpImage.image = [UIImage imageNamed:@"yelp"];
    self.mapYelpImage.alpha = .7f;
    [self.view addSubview:self.mapYelpImage];
}

-(void)segmentChanged:(UISegmentedControl *)segment
{
    if (segment.selectedSegmentIndex == 0) {
        self.mapView.hidden = NO;
        self.tableView.hidden = YES;
        self.mapContainerView.hidden = NO;
        self.mapYelpImage.hidden = NO;
    }
    else
    {
        self.mapView.hidden = YES;
        self.tableView.hidden = NO;
        self.mapContainerView.hidden = YES;
        self.mapYelpImage.hidden = YES;
    }
}

#pragma mark - Explore buttons

// When one of these buttons is pushed...1) remove mapview annotations 2) set search boolean to YES 3) disable user interaction of all the buttons, 4) perform API call with relevent search term.
-(void)button1Selected:(id)sender
{
    // Switch button from picture to text.
    [self setButtonImages];
    [self.button1 setImage:[UIImage new] forState:UIControlStateNormal];
    [self.button1 setTitle:@"Food" forState:UIControlStateNormal];

    NSLog(@"Food search");
    // Flip all other booleans to NO, set the correct search boolean to YES - search booleans are used later to set the proper map annotations
    [self disableSearchBooleans];
    self.foodSearch = YES;

    // Specify proper search parameters...
    self.searchTerm = @"restaurant";
    self.sortType = @0;

    // Remove old map annotations, but add back the Divvy Bike annotation
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    [self clearContainerView];

    // Disable UI while search occurs
    [self disableButtons];

    // Make Yelp call with the proper parameters
    [self makeYelpAPICallwithTerm:self.searchTerm andSortType:self.sortType];
}

-(void)button2Selected:(id)sender
{
    [self setButtonImages];
    [self.button2 setImage:[UIImage new] forState:UIControlStateNormal];
    [self.button2 setTitle:@"Bars" forState:UIControlStateNormal];

    NSLog(@"Bar search");
    // Flip all other booleans to NO, set the correct search boolean to YES - search booleans are used later to set the proper map annotations
    [self disableSearchBooleans];
    self.drinkSearch = YES;

    // Specify proper search parameters...
    self.searchTerm = @"bar";
    self.sortType = @0;

    // Remove old map annotations, but add back the Divvy Bike annotation
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    [self clearContainerView];

    // Disable UI while search occurs
    [self disableButtons];

    // Make Yelp call with the proper parameters
    [self makeYelpAPICallwithTerm:self.searchTerm andSortType:self.sortType];
}

-(void)button3Selected:(id)sender
{
    [self setButtonImages];
    [self.button3 setImage:[UIImage new] forState:UIControlStateNormal];
    [self.button3 setTitle:@"Shop" forState:UIControlStateNormal];

    NSLog(@"Shopping search");
    // Flip all other booleans to NO, set the correct search boolean to YES - search booleans are used later to set the proper map annotations
    [self disableSearchBooleans];
    self.shopSearch = YES;

    // Specify proper search parameters...
    self.searchTerm = @"shop";
    self.sortType = @0;

    // Remove old map annotations, but add back the Divvy Bike annotation
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    [self clearContainerView];

    // Disable UI while search occurs
    [self disableButtons];

    // Make Yelp call with the proper parameters
    [self makeYelpAPICallwithTerm:self.searchTerm andSortType:self.sortType];
}

-(void)button4Selected:(id)sender
{
    [self setButtonImages];
    [self.button4 setImage:[UIImage new] forState:UIControlStateNormal];
    [self.button4 setTitle:@"Sights" forState:UIControlStateNormal];

    // Flip all other booleans to NO, set the correct search boolean to YES - search booleans are used later to set the proper map annotations
    [self disableSearchBooleans];
    self.sightseeSearch = YES;

    // Specify proper search parameters...
    self.searchTerm = @"attractions";
    self.sortType = @0;

    // Remove old map annotations, but add back the Divvy Bike annotation, remove map continer views
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    [self clearContainerView];

    // Disable UI while search occurs
    [self disableButtons];

    // Make Yelp call with the proper parameters
    [self makeYelpAPICallwithTerm:self.searchTerm andSortType:self.sortType];
}

-(void)button5Selected:(id)sender
{
    [self setButtonImages];
    [self.button5 setImage:[UIImage new] forState:UIControlStateNormal];
    [self.button5 setTitle:@"Music" forState:UIControlStateNormal];

    NSLog(@"Live music search");
    // Flip all other booleans to NO, set the correct search boolean to YES - search booleans are used later to set the proper map annotations
    [self disableSearchBooleans];
    self.musicSearch = YES;

    // Specify proper search parameters...
    self.searchTerm = @"music";
    self.sortType = @0;

    // Remove old map annotations, but add back the Divvy Bike annotation
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    [self clearContainerView];

    // Disable UI while search occurs
    [self disableButtons];

    // Make Yelp call with the proper parameters
    [self makeYelpAPICallwithTerm:self.searchTerm andSortType:self.sortType];
}

#pragma mark - map/location manager methods

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

-(void)setMapViewandPlacePin
{
    // Set MapView around Divvy Station
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(self.stationFromSourceVC.latitude.floatValue, self.stationFromSourceVC.longitude.floatValue);
    MKCoordinateSpan span = MKCoordinateSpanMake(.01, .01);
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    self.mapView.showsUserLocation = YES;
    [self.mapView setRegion:region animated:YES];

    // Place Divvy pin annotation
    DivvyBikeAnnotation *annotation = [[DivvyBikeAnnotation alloc] init];
    annotation.coordinate = self.stationFromSourceVC.coordinate;
    annotation.title = self.stationFromSourceVC.stationName;
    annotation.subtitle = [NSString stringWithFormat:@"%.01f miles away", self.stationFromSourceVC.distanceFromUser * 0.000621371];
    annotation.imageName = @"Divvy";
    annotation.backgroundColor = self.stationFromSourceVC.bikesColor;
    annotation.sizeScaler = self.stationFromSourceVC.annotationSizeScaler;
    [self.mapView addAnnotation:annotation];
}

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
        annotationView.frame = CGRectMake(0, 0, (20 + (7.0f * divvyAnnotation.sizeScaler)), (20 + (7.0f * divvyAnnotation.sizeScaler)));
        annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
        annotationView.backgroundColor = divvyAnnotation.backgroundColor;
        return annotationView;
    }

    else if ([annotation isKindOfClass:[FoodAnnotation class]]) {
        FoodAnnotation *foodAnnotation = annotation;
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
        annotationView.image = [UIImage imageNamed:foodAnnotation.imageName];
        annotationView.frame = CGRectMake(0, 0, 30, 30);
        annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
        annotationView.backgroundColor = foodAnnotation.backgroundColor;
        return annotationView;
    }

    else if ([annotation isKindOfClass:[DrinkAnnotation class]]) {
        DrinkAnnotation *drinkAnnotation = annotation;
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
        annotationView.image = [UIImage imageNamed:drinkAnnotation.imageName];
        annotationView.backgroundColor = drinkAnnotation.backgroundColor;
        annotationView.frame = CGRectMake(0, 0, 30, 30);
        annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
        return annotationView;
    }

    else if ([annotation isKindOfClass:[ShopAnnotation class]]) {
        ShopAnnotation *shopAnnotation = annotation;
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
        annotationView.image = [UIImage imageNamed:shopAnnotation.imageName];
        annotationView.frame = CGRectMake(0, 0, 30, 30);
        annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
        annotationView.backgroundColor = shopAnnotation.backgroundColor;
        return annotationView;
    }

    else if ([annotation isKindOfClass:[SightseeAnnotation class]]) {
        SightseeAnnotation *sightseeAnnotation = annotation;
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
        annotationView.image = [UIImage imageNamed:sightseeAnnotation.imageName];
        annotationView.backgroundColor = sightseeAnnotation.backgroundColor;
        annotationView.frame = CGRectMake(0, 0, 30, 30);
        annotationView.layer.cornerRadius = annotationView.frame.size.width/2;

        return annotationView;
    }

    else if ([annotation isKindOfClass:[MusicAnnotation class]]) {
        MusicAnnotation *musicAnnotation = annotation;
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
        annotationView.image = [UIImage imageNamed:musicAnnotation.imageName];
        annotationView.backgroundColor = musicAnnotation.backgroundColor;
        annotationView.frame = CGRectMake(0, 0, 30, 30);
        annotationView.layer.cornerRadius = annotationView.frame.size.width/2;
        return annotationView;
    }
    else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"websegue" sender:self];
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKPinAnnotationView *)view
{
    for (YelpLocation *yelpLocation in self.yelpLocations)
    {
        if ([view.annotation.title isEqualToString:yelpLocation.name]) {
            self.selectedYelpLocation = yelpLocation;
        }
    }
}

#pragma mark - Tableview  methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.yelpLocations.count;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    YelpLocation *location = self.selectedYelpLocation;
    WebviewViewController *detailViewController = segue.destinationViewController;
    detailViewController.yelpLocationFromSourceVC = location;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YelpLocation *yelpLocation = [self.yelpLocations objectAtIndex:indexPath.row];
    YelpTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"yelpcell"];

    // Location name label
    cell.locationName.text = yelpLocation.name;
    cell.locationName.numberOfLines = 0;
    [cell.locationName sizeToFit];
    [cell.locationName setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20]];
    cell.locationName.textColor = [UIColor walkRouteColor];

    // Distance label
    cell.distanceFromStation.text = [NSString stringWithFormat:@"%.01f miles from Divvy Station", yelpLocation.distanceFromStation * 0.000621371];
    [cell.distanceFromStation setFont:[UIFont fontWithName:@"Helvetica" size:12]];
    cell.distanceFromStation.textColor = [UIColor walkRouteColor];

    // neighborhood/offers label.
    [cell.neighborhoodLabel setFont:[UIFont fontWithName:@"Helvetica" size:15]];
    cell.neighborhoodLabel.textColor = [UIColor walkRouteColor];
    cell.neighborhoodLabel.numberOfLines = 0;

    [cell.neighborhoodLabel setFont:[UIFont fontWithName:@"Helvetica" size:15]];
    cell.neighborhoodLabel.textColor = [UIColor walkRouteColor];
    cell.neighborhoodLabel.numberOfLines = 0;
    if (yelpLocation.neighborhood == nil && yelpLocation.offers == nil) {
        cell.neighborhoodLabel.text = @"Neighborhood: N/A\nOffers: N/A";
    }
    else if (yelpLocation.neighborhood && yelpLocation.offers) {
        cell.neighborhoodLabel.text = [NSString stringWithFormat:@"Neighborhood: %@\nOffers: %@", yelpLocation.neighborhood, yelpLocation.offers];
    }
    else if (yelpLocation.neighborhood) {
        cell.neighborhoodLabel.text = [NSString stringWithFormat:@"Neighborhood: %@\nOffers: N/A", yelpLocation.neighborhood];
    }
    else {
        cell.neighborhoodLabel.text = [NSString stringWithFormat:@"Neighborhood: N/A\nOffers: %@", yelpLocation.offers];
    }

    // Business imageview
    [cell.locationImageView sd_setImageWithURL:[NSURL URLWithString:yelpLocation.businessImageURL]
                      placeholderImage:[UIImage imageNamed:@"building"]];
    cell.imageView.clipsToBounds = YES;

    // Star rating imageview
    [cell.ratingImageView sd_setImageWithURL:[NSURL URLWithString:yelpLocation.businessRatingImageURL]
                              placeholderImage:[UIImage imageNamed:@"building"]];
    cell.imageView.clipsToBounds = YES;

    [cell layoutSubviews];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        return 125.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedYelpLocation = [self.yelpLocations objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"websegue" sender:self];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSLog(@"Selected station name: %@", self.selectedYelpLocation.name);
}


#pragma mark - Yelp API call methods
-(void)makeYelpAPICallwithTerm:(NSString *)term andSortType:(NSNumber *) sortType
{
    // Start the activity indicator
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];

    // Sort type 0 - best match (default)
    // Sort type 1 - distance
    // Sort type 2 - highest rated
    NSLog(@"Station Latitude: %f", self.stationFromSourceVC.latitude.floatValue);
    NSLog(@"Station Longitude: %f", self.stationFromSourceVC.longitude.floatValue);
    NSLog(@"Search term: %@", term);
    NSLog(@"Sort type: %@", sortType);

    self.request = [TDOAuth URLRequestForPath:@"/v2/search" GETParameters:@{@"term": term, @"ll": [NSString stringWithFormat:@"%@,%@", self.stationFromSourceVC.latitude, self.stationFromSourceVC.longitude], @"limit" : @20, @"sort" : sortType}
                                         host:@"api.yelp.com"
                                  consumerKey:@"LdaQSTTYqZuYXrta5vVAgw"
                               consumerSecret:@"k6KpVPXHSykD8aQXSXqdi7GboMY"
                                  accessToken:@"VK1B3yDVd9bDc9wNY68TXMM-bt0AWgE-"
                                  tokenSecret:@"sZfenXvsqvtynhp5H5eqfNYZKao"];

    [NSURLConnection sendAsynchronousRequest:self.request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

        // If poor connection...
        if (connectionError) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to retrieve data due to poor network connection" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            [self disableSearchBooleans];
            [self enableButtons];

            // Stop the activity indicator
            self.activityIndicator.hidden = YES;
            [self.activityIndicator stopAnimating];
        }

        else
        {
            NSLog(@"Yelp data received");
            NSDictionary *dictionary  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&connectionError];

            NSMutableArray *arrayOfYelpLocationObjects = [NSMutableArray new];
            NSArray *yelpLocations = [dictionary objectForKey:@"businesses"];

            for (NSDictionary *dictionary in yelpLocations)
            {
                YelpLocation *yelpLocation = [[YelpLocation alloc] init];
                yelpLocation.name = [dictionary objectForKey:@"name"];
                yelpLocation.address = [NSString stringWithFormat:@"%@ %@ %@ %@", [[[dictionary objectForKey:@"location"] objectForKey:@"address"] firstObject], [[dictionary objectForKey:@"location"] objectForKey:@"city"], [[dictionary objectForKey:@"location"] objectForKey:@"state_code"], [[dictionary objectForKey:@"location"] objectForKey:@"postal_code"]];
                yelpLocation.telephone = [dictionary objectForKey:@"phone"];
                yelpLocation.businessMobileURL = [dictionary objectForKey:@"mobile_url"];
                yelpLocation.businessURL = [dictionary objectForKey:@"url"];
                yelpLocation.businessImageURL = [dictionary objectForKey:@"image_url"];
                yelpLocation.neighborhood = [[[dictionary objectForKey:@"location"] objectForKey:@"neighborhoods"] firstObject];;

                if (!yelpLocation.businessImageURL) {
                    NSURL *placeholderURL = [[NSBundle mainBundle] URLForResource:@"building" withExtension:@"png"];
                    NSString *placeholderURLString = [NSString stringWithContentsOfURL:placeholderURL encoding:NSASCIIStringEncoding error:nil];
                    yelpLocation.businessImageURL = placeholderURLString;
                }
                else {
                    yelpLocation.businessImageURL = [dictionary objectForKey:@"image_url"];
                }

                yelpLocation.businessRatingImageURL = [dictionary objectForKey:@"rating_img_url_large"];
                yelpLocation.aboutBusiness = [dictionary objectForKey:@"snippet_text"];
                yelpLocation.distanceFromStation = [[dictionary objectForKey:@"distance"] floatValue];

                if ([[dictionary objectForKey:@"categories"] count] == 3) {
                    yelpLocation.categories = [[[dictionary objectForKey:@"categories"] objectAtIndex:0] objectAtIndex:0];
                    yelpLocation.offers = [NSString stringWithFormat:@"%@, %@", [[[dictionary objectForKey:@"categories"] objectAtIndex:1] objectAtIndex:0], [[[dictionary objectForKey:@"categories"] objectAtIndex:2] objectAtIndex:0]];
                }
                else if ([[dictionary objectForKey:@"categories"] count] == 2) {
                    yelpLocation.categories = [[[dictionary objectForKey:@"categories"] objectAtIndex:0] objectAtIndex:0];
                    yelpLocation.offers = [NSString stringWithFormat:@"%@", [[[dictionary objectForKey:@"categories"] objectAtIndex:1] objectAtIndex:0]];
                }
                else if ([[dictionary objectForKey:@"categories"] count] == 1) {
                    yelpLocation.categories = [[[dictionary objectForKey:@"categories"] objectAtIndex:0] objectAtIndex:0];
                    yelpLocation.offers = @"N/A";
                }
                else {
                    yelpLocation.categories = @"N/A";
                    yelpLocation.offers = @"N/A";
                }
                yelpLocation.yelpID = [dictionary objectForKey:@"id"];
                [arrayOfYelpLocationObjects addObject:yelpLocation];
            }

            // Populate the yelpLocations iVar array.
            self.yelpLocations = [NSArray arrayWithArray:arrayOfYelpLocationObjects];
            NSLog(@"Number of YelpLocations returned: %lu", (unsigned long)self.yelpLocations.count);

            // If no YelpLocations are returned, display alert.
            if (self.yelpLocations.count < 1) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No results found in this area" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                [self disableSearchBooleans];
                [self enableButtons];

                // Stop the activity indicator
                self.activityIndicator.hidden = YES;
                [self.activityIndicator stopAnimating];
            }

            // Otherwise, proceed with geocoding the locations.
            else {
                [self getYelpLocationLatandLong:self.yelpLocations];
            }
        }
    }];
}

-(void)findNeighborhoods
{
    self.request = [TDOAuth URLRequestForPath:@"/v2/search" GETParameters:@{@"ll": [NSString stringWithFormat:@"%@,%@", self.stationFromSourceVC.latitude, self.stationFromSourceVC.longitude], @"limit" : @20, @"sort" : @1}
                                         host:@"api.yelp.com"
                                  consumerKey:@"LdaQSTTYqZuYXrta5vVAgw"
                               consumerSecret:@"k6KpVPXHSykD8aQXSXqdi7GboMY"
                                  accessToken:@"VK1B3yDVd9bDc9wNY68TXMM-bt0AWgE-"
                                  tokenSecret:@"sZfenXvsqvtynhp5H5eqfNYZKao"];

    [NSURLConnection sendAsynchronousRequest:self.request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        // If poor connection...
        if (connectionError) {
            NSLog(@"Connection error - can't find neighborhood");
            self.neighborhoodsLabel.text = @"Neighborhood: N/A";
        }
        else {
            NSDictionary *dictionary  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&connectionError];
            NSArray *yelpLocations = [dictionary objectForKey:@"businesses"];
            NSMutableArray *arrayOfYelpBarObjects = [NSMutableArray new];
            NSMutableArray *neighborhoodsArray2 = [NSMutableArray new];

            for (NSDictionary *dictionary in yelpLocations) {
                YelpLocation *location = [[YelpLocation alloc] init];
                    location.distanceFromStation = [[dictionary objectForKey:@"distance"] floatValue];
                    location.name = [dictionary objectForKey:@"name"];

                NSArray *neighborhoodsArray = [[dictionary objectForKey:@"location"] objectForKey:@"neighborhoods"];
                if (neighborhoodsArray.count > 0) {
                    for (NSString *neighborhood in neighborhoodsArray) {
                        [neighborhoodsArray2 addObject:neighborhood];
                    }
                }
                [arrayOfYelpBarObjects addObject:location];
            }

            NSCountedSet *bag = [[NSCountedSet alloc] initWithArray:neighborhoodsArray2];
            NSString *mostOccurring;
            NSUInteger highest = 0;
            for (NSString *s in bag)
            {
                if ([bag countForObject:s] > highest)
                {
                    highest = [bag countForObject:s];
                    mostOccurring = s;
                }
            }

            self.neighborhood1 = mostOccurring;
            NSMutableArray *secondArray = [NSMutableArray new];

            for (NSString *string in neighborhoodsArray2) {
                if (![string isEqualToString:mostOccurring]) {
                    [secondArray addObject:string];
                }
            }
            NSCountedSet *bag1 = [[NSCountedSet alloc] initWithArray:secondArray];
            NSString *secondMostOccurring;
            NSUInteger secondHighest = 0;
            for (NSString *t in bag1)
            {
                if ([bag1 countForObject:t] > secondHighest) {
                    highest = [bag countForObject:t];
                    secondMostOccurring = t;
                }
            }
            self.neighborhood2 = secondMostOccurring;

            if (!self.neighborhood1 && !self.neighborhood2) {
                self.neighborhoodsLabel.text = @"Neighborhood: N/A";
            }
            else if (self.neighborhood2 && self.neighborhood1) {
                self.neighborhoodsLabel.text = [NSString stringWithFormat:@"Neighborhoods: %@, %@", self.neighborhood1, self.neighborhood2];
            }
            else if (self.neighborhood1) {
                self.neighborhoodsLabel.text = [NSString stringWithFormat:@"Neighborhood: %@", self.neighborhood1];
            }
            else if (self.neighborhood2) {
                self.neighborhoodsLabel.text = [NSString stringWithFormat:@"Neighborhood: %@", self.neighborhood2];
            }
            else {
                self.neighborhoodsLabel.text = @"Neighborhood: N/A";
            }
            NSLog(@"Neighborhood found");
        }
    }];
}

-(void)getYelpLocationLatandLong:(NSArray *)yelpLocations
{
    // Create language query array
    NSMutableArray *languageQueryArray = [[NSMutableArray alloc] init];

    // Set counter to 0
    self.counter = 0;
    for (YelpLocation *yelpLocation in yelpLocations) {

        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:yelpLocation.address
                     completionHandler:^(NSArray* placemarks, NSError* error){

                         // Increment counter every time a yelpLocation address is evaluated.
                         self.counter += 1;

                            // If placemark is found, assign lat and long. properties to yelpLocation object
                            if (placemarks.count > 0) {
                                MKPlacemark *placemark = [placemarks firstObject];
                                yelpLocation.latitude = placemark.location.coordinate.latitude;
                                yelpLocation.longitude = placemark.location.coordinate.longitude;
                            }

                            // Otherwise, add the yelpLocation to the array to be used in the natural language query
                            else {
                                [languageQueryArray addObject:yelpLocation];
                            }

                        // When the counter equals the number of yelpLocations returned, all locations have been evaluated. Now perform natural language query on any bars for which placemarks were not found.
                         if (self.counter == yelpLocations.count) {

                             // If languageQueryArray has at least one object, perform the natural language query method, else, skip to the set pins method.
                             if (languageQueryArray.count > 0) {
                                 NSLog(@"Performing language query on %lu locations", (unsigned long)languageQueryArray.count);
                                 [self performLanguageQuery:languageQueryArray];
                                }
                             else {
                                 NSLog(@"Geocoding completed");
                                 [self removeYelpLocationsWithNoCoordinates];
                                }
                         }
                }];
        }
}

-(void)performLanguageQuery:(NSMutableArray *)queryArray
{
    self.counter2 = 0;
    for (YelpLocation *yelpLocation in queryArray) {

            // Perform natural lanuage query on yelpLocation's name property.
            MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
            request.naturalLanguageQuery = yelpLocation.name;
            request.region = MKCoordinateRegionMake(self.stationFromSourceVC.coordinate, MKCoordinateSpanMake(.3, .3));
            MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];

            [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
                // Increment counter every time a YelpBar address is evaluated.
                self.counter2 += 1;
                NSArray *mapItems = response.mapItems;

                // If there are mapItems returned from query, then set the lat/long properties of YelpLocation and add the MKPointAnnotation to the map.
                if (mapItems.count > 0) {
                    MKMapItem *mapItem = [mapItems firstObject];
                    yelpLocation.latitude = mapItem.placemark.coordinate.latitude;
                    yelpLocation.longitude = mapItem.placemark.coordinate.longitude;
                }

                else {
                    NSLog(@"Could not find location for: %@", yelpLocation.name);
                }
                // When the second counter equals the number of yelpLocations in queryArray, all yelpLocations have been evaluated
                if (self.counter2 == queryArray.count) {
                    NSLog(@"Geocoding completed");
                    [self removeYelpLocationsWithNoCoordinates];
                }
        }];
    }
}

// Remove any yelpLocations with no location coordinates
-(void)removeYelpLocationsWithNoCoordinates
{
    NSMutableArray *tempArray = [NSMutableArray new];

    // Set parameters to keep map from being drawn outside an area around the station, the buffer is a half a degree of longitude and latitude (about 35 miles)
    CGFloat buffer = 0.5f;
    CGFloat stationLatitude = self.stationFromSourceVC.latitude.floatValue;
    CGFloat chicagoLatitudeLowerBound = stationLatitude - buffer;
    CGFloat chicagoLatitudeUpperBound = stationLatitude + buffer;

    CGFloat stationLongitude = self.stationFromSourceVC.longitude.floatValue;
    CGFloat chicagoLongitudeAbsValue = fabsf(stationLongitude);
    CGFloat chicagoLongitudeLowerBound = chicagoLongitudeAbsValue - buffer;
    CGFloat chicagoLongitudeUpperBound = chicagoLongitudeAbsValue + buffer;

    for (YelpLocation *yelpLocation in self.yelpLocations) {
        CGFloat locationLongitudeAbsValue = fabsf(yelpLocation.longitude);

        if (yelpLocation.latitude == 0.0f) {
            NSLog(@"Removed %@ for not having a latitude", yelpLocation.name);
        }
        else if (yelpLocation.longitude == 0.0f) {
            NSLog(@"Removed %@ for not having a longitude", yelpLocation.name);
        }
        else if (chicagoLatitudeLowerBound > yelpLocation.latitude && yelpLocation.latitude > chicagoLatitudeUpperBound) {
            NSLog(@"Removed %@ for having a latitude outside the bounds of chicago", yelpLocation.name);
            }
        else if (chicagoLongitudeLowerBound > locationLongitudeAbsValue && locationLongitudeAbsValue > chicagoLongitudeUpperBound) {
            NSLog(@"Removed %@ for having a longitude outside the bounds of chicago", yelpLocation.name);
            }
        else {
            [tempArray addObject:yelpLocation];
        }
    }

    self.yelpLocations = [NSArray arrayWithArray:tempArray];
    if (self.yelpLocations.count < 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Sorry, could not locate %@ in this area", self.searchTerm] message:@"Please try again" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alert show];
        [self enableButtons];
    }
    else {
        [self setYelpPinAnnotations];
        NSLog(@"Yelplocations mapped and listed %lu", (unsigned long)self.yelpLocations.count);
    }
}

-(void)setYelpPinAnnotations
{
    for (YelpLocation *yelpLocation in self.yelpLocations) {
        // If yelplocation latitude and longitude coordinates exist, set appropriate annotations.
        if (yelpLocation.latitude && yelpLocation.latitude) {

            if (self.foodSearch) {
                FoodAnnotation *foodannotation = [[FoodAnnotation alloc] init];
                foodannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
                foodannotation.title = yelpLocation.name;
                foodannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
                foodannotation.imageName = @"food";
                foodannotation.backgroundColor = [UIColor walkRouteColor];
                [self.mapView addAnnotation:foodannotation];
        }
            else if (self.drinkSearch) {
                DrinkAnnotation *drinkannotation = [[DrinkAnnotation alloc] init];
                drinkannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
                drinkannotation.title = yelpLocation.name;
                drinkannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
                drinkannotation.imageName = @"drink";
                drinkannotation.backgroundColor = [UIColor walkRouteColor];
                [self.mapView addAnnotation:drinkannotation];
        }
            else if (self.shopSearch) {
                ShopAnnotation *shopannotation = [[ShopAnnotation alloc] init];
                shopannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
                shopannotation.title = yelpLocation.name;
                shopannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
                shopannotation.imageName = @"shop";
                shopannotation.backgroundColor = [UIColor walkRouteColor];
                [self.mapView addAnnotation:shopannotation];
        }
            else if (self.sightseeSearch) {
                SightseeAnnotation *sightseeannotation = [[SightseeAnnotation alloc] init];
                sightseeannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
                sightseeannotation.title = yelpLocation.name;
                sightseeannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
                sightseeannotation.imageName = @"sightsee";
                sightseeannotation.backgroundColor = [UIColor walkRouteColor];
                [self.mapView addAnnotation:sightseeannotation];
        }
            else {
            MusicAnnotation *musicsannotation = [[MusicAnnotation alloc] init];
            musicsannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
            musicsannotation.title = yelpLocation.name;
            musicsannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
            musicsannotation.imageName = @"music";
            musicsannotation.backgroundColor = [UIColor walkRouteColor];
            [self.mapView addAnnotation:musicsannotation];
        }
        }
    }
    // Enable user interaction of buttons, reload tableview, create the mapcontainer view, scale map to fit the annotations, display the segmented control, stop the activity indictor.
    [self enableButtons];
    [self.tableView reloadData];
    [self createMapContainerView];
    [self scaleMapViewToFitAnnotations];
    self.segmentedControl.enabled = YES;

    // Stop the activity indicator
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];

    NSLog(@"Set pins method completed");
}

#pragma mark - Map container view methods

-(void)createMapContainerView
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat containerViewHeight = 40.0f;
    CGFloat containerViewWidth = 40.0f;
    CGFloat horizontalOffset = self.view.frame.size.width - containerViewWidth -10.0f;
    CGFloat verticalOffset = self.view.frame.size.height - tabBarHeight - containerViewHeight -10.0f;

    // Create view to hold the map information vies.
    self.mapContainerView = [[UIView alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, containerViewWidth, containerViewHeight)];
    [self.view addSubview:self.mapContainerView];

    // Add the "i" info icon to mapcontainer view.
    UIImageView *searchMoreImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.mapContainerView.frame.size.width, self.mapContainerView.frame.size.height)];
    searchMoreImageView.backgroundColor = [UIColor walkRouteColor];
    searchMoreImageView.image = [UIImage imageNamed:@"info"];
    searchMoreImageView.alpha = 0.8f;
    searchMoreImageView.layer.cornerRadius = containerViewHeight/2;
    [self.mapContainerView addSubview:searchMoreImageView];

    // Add tap gesture recognizer to mapcontainer view
    self.tapToOpenMapContainer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openContainer:)];
    [self.mapContainerView addGestureRecognizer:self.tapToOpenMapContainer];

    NSLog(@"Created map container view");
}

-(void)openContainer:(id)sender
{
    // Remove the tap gesture recognizer that opened the container view
    [self.mapContainerView removeGestureRecognizer:self.tapToOpenMapContainer];

    // Remove label from the container view
    NSArray *subviews = [self.mapContainerView subviews];
    for (UILabel *label in subviews) {
        [label removeFromSuperview];
    }

    // Resize the container view with animation
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat containerViewHeight = 60.0f;
    CGFloat containerViewWidth = self.view.frame.size.width;
    CGFloat horizontalOffset = self.view.frame.origin.x;
    CGFloat verticalOffset = self.view.frame.size.height - tabBarHeight - containerViewHeight;

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];

    self.mapContainerView.frame = CGRectMake(horizontalOffset, verticalOffset, containerViewWidth, containerViewHeight);
    [UIView commitAnimations];

    // Add buttons to map container view

    // Create and style the two buttons.
    NSMutableArray *buttonsArray = [NSMutableArray new];

    UIButton *button1 = [[UIButton alloc] init];
    button1.backgroundColor = [UIColor whiteColor];
    [button1 setTitleColor:[UIColor walkRouteColor] forState:UIControlStateNormal];
    button1.layer.borderColor = [[UIColor walkRouteColor] CGColor];
    button1.layer.borderWidth = 1.0f;
    [button1 setTitle:@"Nearest" forState:UIControlStateNormal];

    UIButton *button2 = [[UIButton alloc] init];
    button2.backgroundColor = [UIColor walkRouteColor];
    [button2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button2 setTitle:@"Highest\nRated" forState:UIControlStateNormal];
    button2.titleLabel.numberOfLines = 0;
    button2.titleLabel.textAlignment = NSTextAlignmentCenter;

    [buttonsArray addObject:button1];
    [buttonsArray addObject:button2];

    // Place the buttons one on top of the other in the container view.
    verticalOffset = 0.0;
    horizontalOffset = 0.0f;
    CGFloat buttonWidth = self.mapContainerView.frame.size.width/2;
    CGFloat buttonHeight = self.mapContainerView.frame.size.height;

    for (UIButton *button in buttonsArray) {
        button.frame = CGRectMake(horizontalOffset, verticalOffset, buttonWidth, buttonHeight);
        button.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0];
        [self.mapContainerView addSubview:button];
        horizontalOffset += button.frame.size.width;
    }

    // Set button targets.
    [button1 addTarget:self
                action:@selector(nearestSelected:)
      forControlEvents:UIControlEventTouchUpInside];

    [button2 addTarget:self
                action:@selector(topRatedSelected:)
      forControlEvents:UIControlEventTouchUpInside];

    // Add tap that will close the mapContainer view, when the user taps anywhere on the view.
    self.tapToCloseMapContainer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeContainer:)];
    [self.view addGestureRecognizer:self.tapToCloseMapContainer];

    // Disable buttons while the container view is pulled out, so a tap anywhere will close the container view.
    [self disableButtons];
}

-(void)closeContainer:(id)sender
{
    // Remove buttons from the container view
    [self clearContainerView];

    // Resize the container view with animation back to its original size.
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];

    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat containerViewHeight = 40.0;
    CGFloat containerViewWidth = 40.0;
    CGFloat horizontalOffset = self.view.frame.size.width - containerViewWidth -10.0f;
    CGFloat verticalOffset = self.view.frame.size.height - tabBarHeight - containerViewHeight -10.0f;
    self.mapContainerView.frame = CGRectMake(horizontalOffset, verticalOffset, containerViewWidth, containerViewHeight);
    [UIView commitAnimations];

    // Add the "i" icon back to mapcontainer view.
    UIImageView *searchMoreImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.mapContainerView.frame.size.width, self.mapContainerView.frame.size.height)];
    searchMoreImageView.backgroundColor = [UIColor walkRouteColor];
    searchMoreImageView.image = [UIImage imageNamed:@"info"];
    searchMoreImageView.alpha = 0.8f;
    searchMoreImageView.layer.cornerRadius = containerViewHeight/2;
    [self.mapContainerView addSubview:searchMoreImageView];

    // Remove the close gesture recognizer..
    [self.view removeGestureRecognizer:self.tapToCloseMapContainer];

    // Add the open gesture recognizer
    [self.mapContainerView addGestureRecognizer:self.tapToOpenMapContainer];

    // Enable the buttons on the screen
    [self enableButtons];
}

-(void)nearestSelected:(id)sender
{
    [self.view removeGestureRecognizer:self.tapToCloseMapContainer];

    //Remove mapview annotations
    [self.mapView removeAnnotations:self.mapView.annotations];

    //Disable user interaction
    [self disableButtons];

    // Remove buttons from the container view
    [self clearContainerView];

    NSLog(@"Find nearest button selected");
    // Perform an API call with returned results sorted by distance.
    self.sortType = @1;
    [self makeYelpAPICallwithTerm:self.searchTerm andSortType:self.sortType];
}

-(void)topRatedSelected:(id)sender
{
    [self.view removeGestureRecognizer:self.tapToCloseMapContainer];

    //Remove mapview annotations
    [self.mapView removeAnnotations:self.mapView.annotations];

    //Disable user interaction
    [self disableButtons];

    // Remove buttons from the container view
    [self clearContainerView];

    NSLog(@"Find highest rated button selected");
    // Perform an API call with returned results sorted by highest rated.
    self.sortType = @2;
    [self makeYelpAPICallwithTerm:self.searchTerm andSortType:self.sortType];
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

-(void)clearContainerView
{
    NSArray *subviews = [self.mapContainerView subviews];
    for (UILabel *label in subviews) {
        [label removeFromSuperview];
    }
    for (UIButton *button in subviews) {
        [button removeFromSuperview];
    }
}

-(void)disableSearchBooleans
{
    self.foodSearch = NO;
    self.drinkSearch = NO;
    self.shopSearch = NO;
    self.sightseeSearch = NO;
    self.musicSearch = NO;
}

-(void)setButtonImages
{
    [_button1 setImage:[UIImage imageNamed:@"foodcolor"] forState:UIControlStateNormal];
    [_button2 setImage:[UIImage imageNamed:@"drinkcolor"] forState:UIControlStateNormal];
    [_button3 setImage:[UIImage imageNamed:@"shopcolor"] forState:UIControlStateNormal];
    [_button4 setImage:[UIImage imageNamed:@"sightseecolor"] forState:UIControlStateNormal];
    [_button5 setImage:[UIImage imageNamed:@"guitarcolor"] forState:UIControlStateNormal];
}

// Scales the map view appropriately to include both origin and destination location.
-(void)scaleMapViewToFitAnnotations
{
    // Instatitate top left and lower right coordinates
    CLLocationCoordinate2D topLeftCoord;
    CLLocationCoordinate2D bottomRightCoord;

    //Set initial values of longitude and latitude to their max/min values
    CGFloat lowestLongitude =180.0f;
    CGFloat highestLatitude = -90.0f;
    CGFloat highestLongitude = -180.0f;
    CGFloat lowestLatitude = 90.0f;

    // Set parameters to keep map from being drawn outside an area around the station, the buffer is a half a degree of longitude and latitude (about 35 miles)
    CGFloat buffer = 0.5f;
    CGFloat stationLatitude = self.stationFromSourceVC.latitude.floatValue;
    CGFloat chicagoLatitudeLowerBound = stationLatitude - buffer;
    CGFloat chicagoLatitudeUpperBound = stationLatitude + buffer;

    CGFloat stationLongitude = self.stationFromSourceVC.longitude.floatValue;
    CGFloat chicagoLongitudeAbsValue = fabsf(stationLongitude);
    CGFloat chicagoLongitudeLowerBound = chicagoLongitudeAbsValue - buffer;
    CGFloat chicagoLongitudeUpperBound = chicagoLongitudeAbsValue + buffer;

    // Iterate through yelplocations and assign highest and lowest latitude
    for (YelpLocation *yelpLocation in self.yelpLocations) {
        if (!yelpLocation.latitude == 0.0f || !yelpLocation.longitude == 0.0f) {
            CGFloat locationLatitude = yelpLocation.latitude;
            CGFloat locationLongitude = yelpLocation.longitude;
            CGFloat locationLongitudeAbsValue = fabsf(locationLongitude);

            if (chicagoLatitudeLowerBound < locationLatitude && locationLatitude < chicagoLatitudeUpperBound) {
                highestLatitude = fmax(locationLatitude, highestLatitude);
                lowestLatitude = fmin(locationLatitude, lowestLatitude);
            }
                else {
                    NSLog(@"Latitude found outside chicago %f", locationLatitude);
                }

            if (chicagoLongitudeLowerBound < locationLongitudeAbsValue && locationLongitudeAbsValue < chicagoLongitudeUpperBound) {
                lowestLongitude = fmin(locationLongitude, lowestLongitude);
                highestLongitude = fmax(locationLongitude, highestLongitude);
            }
            else {
                NSLog(@"Longitude found outside chicago %f", locationLongitude);
            }
        }
        else {
            NSLog(@"Location has no coordinates: %f, %f", yelpLocation.latitude, yelpLocation.longitude);
        }
    }

    topLeftCoord.longitude = lowestLongitude;
    topLeftCoord.latitude = highestLatitude;
    bottomRightCoord.longitude = highestLongitude;
    bottomRightCoord.latitude = lowestLatitude;

    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.3;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.3;

    // Adding some buffer space to the mapview
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.5;
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.5;

    region = [self.mapView regionThatFits:region];
    [self.mapView setRegion:region animated:YES];
}


@end
