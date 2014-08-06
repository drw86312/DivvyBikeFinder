//
//  DataViewController.m
//  Divvy & Conquer
//
//  Created by David Warner on 8/5/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "DataViewController.h"
#import "UIColor+DesignColors.h"
#import "UIFont+DesignFonts.h"
#import "DivvyData.h"

@interface DataViewController ()

@property DivvyData *divvyData;

@end

@implementation DataViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getJSON];
}


-(void)getJSON
{
    NSLog(@"Getting JSON");

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
         }

         // If no connection error
         else {
             // Serialize the returned JSON and assign properties to divvyStation objects
             NSDictionary *dictionary  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&connectionError];
             NSArray *stationsArray = [dictionary objectForKey:@"stationBeanList"];

             CGFloat bikesCounter = 0.0f;
             CGFloat docksCounter = 0.0f;
             CGFloat totalDocksCounter = 0.0f;
             CGFloat stationCounter = 0.0f;
             CGFloat emptyStationsCounter = 0.0f;
             CGFloat fullStationsCounter = 0.0f;

             for (NSDictionary *dictionary in stationsArray) {
                 docksCounter += [[dictionary objectForKey:@"availableDocks"] floatValue];
                 bikesCounter += [[dictionary objectForKey:@"availableBikes"] floatValue];
                 totalDocksCounter += [[dictionary objectForKey:@"totalDocks"] floatValue];
                 stationCounter += 1;

                 if ([[dictionary objectForKey:@"availableDocks"] floatValue] == 0) {
                     fullStationsCounter += 1.0f;
                 }
                 if ([[dictionary objectForKey:@"availableBikes"] floatValue] == 0) {
                     emptyStationsCounter += 1.0f;
                 }
             }

             _divvyData = [[DivvyData alloc] init];
             _divvyData.totalStations = [NSNumber numberWithFloat:stationCounter];
             _divvyData.bikes = [NSNumber numberWithFloat:bikesCounter];;
             _divvyData.docks = [NSNumber numberWithFloat:docksCounter];;
             _divvyData.totalDocksGiven = [NSNumber numberWithFloat:totalDocksCounter];
             _divvyData.totalDocksCalculated = [NSNumber numberWithFloat:(docksCounter + bikesCounter)];
             _divvyData.emptyStations = [NSNumber numberWithFloat:emptyStationsCounter];
             _divvyData.fullStations = [NSNumber numberWithFloat:fullStationsCounter];

             NSLog(@"Number of stations: %@", _divvyData.totalStations);
             NSLog(@"Total Available Bikes: %@", _divvyData.bikes);
             NSLog(@"Total Available Docks: %@", _divvyData.docks);
             NSLog(@"Total Docks Given: %@", _divvyData.totalDocksGiven);
             NSLog(@"Total Docks Calculated: %@", _divvyData.totalDocksCalculated);
             [self createInformationLabels];
         }
     }];
}

-(void)createInformationLabels
{
//    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
//    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;

    CGFloat labelWidth = 310.0f;
    CGFloat labelHeight = 360;
    CGFloat horizontalOffset = (self.view.frame.size.width - labelWidth)/2;
    CGFloat verticalOffset = (self.view.frame.size.height/2) - (labelHeight/2);

    CGFloat ratioBikes = self.divvyData.bikes.floatValue/(self.divvyData.bikes.floatValue + self.divvyData.docks.floatValue);
    CGFloat ratioDocks = self.divvyData.docks.floatValue/(self.divvyData.bikes.floatValue + self.divvyData.docks.floatValue);
    NSString *percentBikes= [NSString stringWithFormat:@"%.01f", ratioBikes * 100];
    NSString *percentDocks= [NSString stringWithFormat:@"%.01f", ratioDocks * 100];

    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, labelHeight)];
    infoLabel.text = [NSString stringWithFormat:@"Number of Stations: %@\n\nEmpty Stations: %@\n\nFull Stations: %@\n\nTotal available bikes: %@\n\nTotal available docks: %@\n\nTotal Docks Given: %@\n\nTotal Docks Calculated: %@\n\nBikes Percent of Total: %@%%\n\nDocks Percent of total: %@%%", self.divvyData.totalStations, self.divvyData.emptyStations, self.divvyData.fullStations, self.divvyData.bikes, self.divvyData.docks, self.divvyData.totalDocksGiven, self.divvyData.totalDocksCalculated, percentBikes, percentDocks];
    infoLabel.backgroundColor = [UIColor divvyColor];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.font = [UIFont bigFontBold];
    infoLabel.numberOfLines = 0;
    infoLabel.textAlignment = NSTextAlignmentCenter;

    [self.view addSubview:infoLabel];

    verticalOffset += infoLabel.frame.size.height + 10.0f;

    UIButton *refreshButton = [[UIButton alloc] initWithFrame:CGRectMake(horizontalOffset, verticalOffset, labelWidth, 50.0f)];
    refreshButton.backgroundColor = [UIColor walkRouteColor];
    refreshButton.layer.cornerRadius = 5.0f;
    [refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    refreshButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [refreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    refreshButton.titleLabel.font = [UIFont bigFontBold];
    [refreshButton addTarget:self
                action:@selector(refreshSelected:)
      forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:refreshButton];

}

-(void)refreshSelected:(id)sender
{
    NSLog(@"Refresh button clicked");
    [self getJSON];
}












@end
