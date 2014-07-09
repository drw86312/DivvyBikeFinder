//
//  StationDetailViewController.h
//  DivvyBikeFinder
//
//  Created by David Warner on 7/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DivvyStation.h"
#import <MapKit/MapKit.h>

@interface StationDetailViewController : UIViewController

@property DivvyStation *stationFromSourceVC;
@property CLLocation *userLocationFromSourceVC;
@property NSString *userLocationStringFromSource;

@end
