//
//  DivvyStation.h
//  DivvyBikeFinder
//
//  Created by David Warner on 6/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface DivvyStation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) CLLocationDistance distanceFromUser;
@property (nonatomic, assign) CLLocationDistance distanceFromDestination;

@property NSNumber *identifier;
@property NSString *stationName;
@property NSNumber *availableDocks;
@property NSNumber *totalDocks;
@property NSNumber *latitude;
@property NSNumber *longitude;
@property NSString *statusValue;
@property NSNumber *statusKey;
@property NSNumber *availableBikes;
@property NSString *streetAddress1;
@property NSString *streetAddress2;
@property NSString *city;
@property NSString *postalCode;
@property NSString *location;
@property NSString *landMark;
@property (nonatomic, strong) UIColor *bikesColor;
@property (nonatomic, strong) UIColor *docksColor;
@property CGFloat annotationSize;

@end
