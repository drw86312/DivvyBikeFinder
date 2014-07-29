//
//  UIColor+DesignColors.m
//  PubChatter
//
//  Created by Yeah Right on 6/26/14.
//  Copyright (c) 2014 Naomi Himley. All rights reserved.
//

#import "UIColor+DesignColors.h"

@implementation UIColor (DesignColors)

+ (UIColor *)divvyColor
{
    CGFloat red = 61.0/255.0;
    CGFloat green = 183.0/255.0;
    CGFloat blue = 228.0/255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

+ (UIColor *)walkRouteColor
{
    CGFloat red = 252.0/255.0;
    CGFloat green = 90.0/255.0;
    CGFloat blue = 58.0/255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

@end