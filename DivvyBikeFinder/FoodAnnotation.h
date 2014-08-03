//
//  FoodAnnotation.h
//  DivvyBikeFinder
//
//  Created by David Warner on 7/29/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface FoodAnnotation : MKPointAnnotation

@property(nonatomic, strong) NSString *imageName;
@property(nonatomic, strong) UIColor *backgroundColor;

@end
