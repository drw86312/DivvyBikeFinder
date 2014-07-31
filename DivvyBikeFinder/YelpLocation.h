//
//  YelpLocation.h
//  DivvyBikeFinder
//
//  Created by David Warner on 7/29/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YelpLocation : NSObject

@property NSString *yelpID;
@property NSString *name;
@property NSString *address;
@property NSString *telephone;
@property CGFloat latitude;
@property CGFloat longitude;
@property (nonatomic, assign) CGFloat distanceFromUser;
@property (nonatomic, assign) CGFloat distanceFromStation;
@property NSString *businessURL;
@property NSString *businessImageURL;
@property NSString *businessRatingImageURL;
@property NSString *businessMobileURL;
@property NSString *aboutBusiness;
@property NSString *categories;
@property NSString *offers;
@property NSString *neighborhood;

@end
