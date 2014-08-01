//
//  DivvyBikeAnnotation.h
//  DivvyBikeFinder
//
//  Created by David Warner on 7/7/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface DivvyBikeAnnotation : MKPointAnnotation

@property(nonatomic, strong) NSString *imageName;
@property(nonatomic, strong) UIColor *backgroundColor;

@end
