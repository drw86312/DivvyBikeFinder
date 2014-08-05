//
//  UIFont+DesignFonts.m
//  DivvyBikeFinder
//
//  Created by David Warner on 8/3/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "UIFont+DesignFonts.h"

@implementation UIFont (DesignFont)

+ (UIFont *)smallFont
{
    return [UIFont fontWithName:@"STHeitiTC-Light" size:12.0f];
}

+ (UIFont *)smallMediumFont
{
    return [UIFont fontWithName:@"STHeitiTC-Light" size:15.0f];
}

+ (UIFont *)mediumFont
{
    return [UIFont fontWithName:@"STHeitiTC-Light" size:17.0f];
}

+ (UIFont *)bigFont
{
    return [UIFont fontWithName:@"STHeitiTC-Light" size:21.0f];
}

+ (UIFont *)smallFontBold
{
    return [UIFont fontWithName:@"STHeitiTC-Medium" size:12.0f];
}

+ (UIFont *)smallMediumFontBold
{
    return [UIFont fontWithName:@"STHeitiTC-Light" size:15.0f];
}

+ (UIFont *)mediumFontBold
{
    return [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0f];
}

+ (UIFont *)bigFontBold
{
    return [UIFont fontWithName:@"STHeitiTC-Medium" size:21.0f];
}

+ (UIFont *)hugeFont
{
    return [UIFont fontWithName:@"STHeitiTC-Light" size:50.0f];
}

+ (UIFont *)hugeFontBold
{
    return [UIFont fontWithName:@"STHeitiTC-Medium" size:50.0f];
}

@end
