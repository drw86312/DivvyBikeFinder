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
#import <MapKit/MapKit.h>
#import "YelpLocation.h"
#import "FoodAnnotation.h"
#import "DrinkAnnotation.h"
#import "ShopAnnotation.h"
#import "MusicAnnotation.h"
#import "SightseeAnnotation.h"
#import "UIImageView+WebCache.h"
#import "YelpTableViewCell.h"
#import "TDOAuth.h"

@interface StationDetailViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property CLLocationManager *locationManager;
@property UIView *backgroundView;
@property NSMutableArray *buttonsArray;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSString *neighborhood1;
@property NSString *neighborhood2;
@property UILabel *neighborhoodsLabel;
@property NSArray *yelpLocations;
@property NSInteger counter;
@property NSInteger counter2;
@property UIActivityIndicatorView *activityIndicator;
@property id request;
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

    self.tableView.separatorColor = [UIColor walkRouteColor];
}

-(void)makeStationDetailView
{
    // Find status and navigation bar heights and set spacing between views
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat backgroundViewHeight = 75.0f;
    CGFloat spacing = 5.0f;

    // Create a background view to hold station details
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, navBarHeight + statusBarHeight, self.view.frame.size.width, backgroundViewHeight)];
    [self.view addSubview:self.backgroundView];

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Add the station label
    CGFloat verticalOffset = spacing;
    CGFloat horizontalOffset = spacing;
    CGFloat stationLabelWidth = 200.0f;
    CGFloat stationLabelHeight = 50.0f;

    UILabel *stationLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, stationLabelWidth, stationLabelHeight)];
    stationLabel.text = [NSString stringWithFormat:@"%@", self.stationFromSourceVC.stationName];
    stationLabel.textColor = [UIColor divvyColor];
    [stationLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:17]];
    stationLabel.numberOfLines = 0;
    [self.backgroundView addSubview:stationLabel];

    horizontalOffset += stationLabel.frame.size.width + spacing;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    // Add the neighborhoods label - must be a property as its text gets set in the findNeighborhoods method.
    CGFloat neighborhoodsLabelWidth = self.view.frame.size.width - (horizontalOffset + spacing);
    CGFloat neighborhoodsLabelHeight = 50.0f;

    self.neighborhoodsLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, neighborhoodsLabelWidth , neighborhoodsLabelHeight)];
    self.neighborhoodsLabel.numberOfLines = 0;
    self.neighborhoodsLabel.textAlignment = NSTextAlignmentRight;
    self.neighborhoodsLabel.textColor = [UIColor divvyColor];
    [self.neighborhoodsLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
    [self.backgroundView addSubview:self.neighborhoodsLabel];

    verticalOffset = verticalOffset + stationLabel.frame.size.height;
    horizontalOffset = spacing;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    CGFloat addressLabelHeight = 20.0f;

    UILabel *addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, self.view.frame.size.width - (2 * spacing), addressLabelHeight)];
    addressLabel.text = [NSString stringWithFormat:@"%@ Chicago IL", self.stationFromSourceVC.location];
    addressLabel.textColor = [UIColor divvyColor];
    [addressLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:15]];

    [self.backgroundView addSubview:addressLabel];

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
    CGFloat horizontalOffset = 5.0f;
    CGFloat buttonWidth = (self.view.frame.size.width - ((self.buttonsArray.count + 1) * spacing))/ self.buttonsArray.count;
    CGFloat buttonHeight = 40.0f;

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
    [button5 setTitle:@"Music" forState:UIControlStateNormal];

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

#pragma mark - Explore buttons

// When one of these buttons is pushed...1) remove mapview annotations 2) set search boolean to YES 3) disable user interaction of all the buttons, 4) perform API call with relevent search term.
-(void)button1Selected:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    self.foodSearch = YES;
    [self disableButtons];
    [self makeYelpAPICallwithTerm:@"restaurant" andSortType:@0];
}

-(void)button2Selected:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    self.drinkSearch = YES;
    [self disableButtons];
    [self makeYelpAPICallwithTerm:@"bar" andSortType:@0];
}

-(void)button3Selected:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    self.shopSearch = YES;
    [self disableButtons];
    [self makeYelpAPICallwithTerm:@"shop" andSortType:@0];
}

-(void)button4Selected:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    self.sightseeSearch = YES;
    [self disableButtons];
    [self makeYelpAPICallwithTerm:@"attractions" andSortType:@0];
}

-(void)button5Selected:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self setMapViewandPlacePin];
    self.musicSearch = YES;
    [self disableButtons];
    [self makeYelpAPICallwithTerm:@"music" andSortType:@0];
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
    DivvyBikeAnnotation *divvyAnnotation = [[DivvyBikeAnnotation alloc] init];
    divvyAnnotation.coordinate = self.stationFromSourceVC.coordinate;
    divvyAnnotation.title = self.stationFromSourceVC.stationName;
    divvyAnnotation.subtitle = [NSString stringWithFormat:@"%.01f miles away", self.stationFromSourceVC.distanceFromUser * 0.000621371];
    divvyAnnotation.imageName = @"Divvy";
    [self.mapView addAnnotation:divvyAnnotation];
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
        annotationView.tintColor = [UIColor greenColor];

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
        annotationView.tintColor = [UIColor redColor];

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
        annotationView.tintColor = [UIColor blueColor];

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
        annotationView.tintColor = [UIColor yellowColor];

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
        annotationView.tintColor = [UIColor orangeColor];

        return annotationView;
    }
    else {
        return nil;
    }
}

#pragma mark - Tableview  methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.yelpLocations.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YelpLocation *yelpLocation = [self.yelpLocations objectAtIndex:indexPath.row];
    YelpTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"yelpcell"];

    cell.locationName.text = yelpLocation.name;
    cell.locationName.numberOfLines = 0;
    [cell.locationName setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20]];
    cell.locationName.textColor = [UIColor walkRouteColor];

    cell.distanceFromStation.text = [NSString stringWithFormat:@"%.01f miles from Divvy Station", yelpLocation.distanceFromStation * 0.000621371];
    [cell.distanceFromStation setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
    cell.distanceFromStation.textColor = [UIColor walkRouteColor];

    [cell.neighborhoodLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15]];
    cell.neighborhoodLabel.textColor = [UIColor walkRouteColor];
    cell.neighborhoodLabel.numberOfLines = 0;

    if (yelpLocation.neighborhood == nil) {
        cell.neighborhoodLabel.text = @"Area: N/A";
    }
    else {
        cell.neighborhoodLabel.text = [NSString stringWithFormat:@"Area: %@", yelpLocation.neighborhood];
    }

    [cell.locationImageView sd_setImageWithURL:[NSURL URLWithString:yelpLocation.businessImageURL]
                      placeholderImage:[UIImage imageNamed:@"building"]];
    cell.imageView.clipsToBounds = YES;

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


#pragma mark - Yelp API call methods
-(void)makeYelpAPICallwithTerm:(NSString *)term andSortType:(NSNumber *) sortType
{
    // Start the activity indicator
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];

    // Sort type 0 - is a sort by best match
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
            NSLog(@"Yelp data returned");
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

                NSLog(@"neighborhood: %@", yelpLocation.neighborhood);

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
                    yelpLocation.offers = @"n/a";
                }
                else {
                    yelpLocation.categories = @"n/a";
                    yelpLocation.offers = @"n/a";
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
        if (connectionError) {NSLog(@"Connection error");}
        else {
            NSLog(@"Yelp data returned");
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
                        NSLog(@"Neighborhood: %@", neighborhood);
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
                if ([bag1 countForObject:t] > secondHighest)
                {
                    highest = [bag countForObject:t];
                    secondMostOccurring = t;
                }
            }

            self.neighborhood2 = secondMostOccurring;

            NSLog(@"Most Occuring Hood: %@", self.neighborhood1);
            NSLog(@"SecondMost Occuring Hood: %@", self.neighborhood2);
            self.neighborhoodsLabel.text = [NSString stringWithFormat:@"Neighborhoods\n%@\n%@", self.neighborhood1, self.neighborhood2];

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
                                NSLog(@"Result found");
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
                                 NSLog(@"Setting yelp pins after address geocode");
                                 [self setYelpPinAnnotations];
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
                    NSLog(@"Result found");
                    MKMapItem *mapItem = [mapItems firstObject];
                    yelpLocation.latitude = mapItem.placemark.coordinate.latitude;
                    yelpLocation.longitude = mapItem.placemark.coordinate.longitude;
                }

                else {
                    NSLog(@"Could not find location for: %@", yelpLocation.name);
                }

                // When the second counter equals the number of yelpLocations in queryArray, all yelpLocations have been evaluated
                if (self.counter2 == queryArray.count) {
                    NSLog(@"Setting yelp pins after natural language query");
                    [self setYelpPinAnnotations];
                }
        }];
    }
}

-(void)setYelpPinAnnotations
{
    for (YelpLocation *yelpLocation in self.yelpLocations) {
        if (self.foodSearch) {
            FoodAnnotation *foodannotation = [[FoodAnnotation alloc] init];
            foodannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
            foodannotation.title = yelpLocation.name;
            foodannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
            foodannotation.imageName = @"food";
            [self.mapView addAnnotation:foodannotation];
        }
        else if (self.drinkSearch) {
            DrinkAnnotation *drinkannotation = [[DrinkAnnotation alloc] init];
            drinkannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
            drinkannotation.title = yelpLocation.name;
            drinkannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
            drinkannotation.imageName = @"drink";
            [self.mapView addAnnotation:drinkannotation];
        }
        else if (self.shopSearch) {
            ShopAnnotation *shopannotation = [[ShopAnnotation alloc] init];
            shopannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
            shopannotation.title = yelpLocation.name;
            shopannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
            shopannotation.imageName = @"shop";
            [self.mapView addAnnotation:shopannotation];
        }
        else if (self.sightseeSearch) {
            SightseeAnnotation *sightseeannotation = [[SightseeAnnotation alloc] init];
            sightseeannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
            sightseeannotation.title = yelpLocation.name;
            sightseeannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
            sightseeannotation.imageName = @"sightsee";
            [self.mapView addAnnotation:sightseeannotation];
        }
        else {
            MusicAnnotation *musicsannotation = [[MusicAnnotation alloc] init];
            musicsannotation.coordinate = CLLocationCoordinate2DMake(yelpLocation.latitude, yelpLocation.longitude);
            musicsannotation.title = yelpLocation.name;
            musicsannotation.subtitle = [NSString stringWithFormat:@"%.01f miles", yelpLocation.distanceFromStation * 0.000621371];
            musicsannotation.imageName = @"music";
            [self.mapView addAnnotation:musicsannotation];
        }
    }

    // Set all search booleans back to NO and enable user interaction of the buttons.
    [self disableSearchBooleans];
    [self enableButtons];
    [self.tableView reloadData];

    // Stop the activity indicator
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];

    NSLog(@"Set pins method completed");
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

-(void)disableSearchBooleans
{
    self.foodSearch = NO;
    self.drinkSearch = NO;
    self.shopSearch = NO;
    self.sightseeSearch = NO;
    self.musicSearch = NO;
}



@end
