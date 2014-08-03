//
//  RouteTableViewCell.h
//  DivvyBikeFinder
//
//  Created by David Warner on 7/25/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RouteTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *stepLabel;
@property (weak, nonatomic) IBOutlet UIImageView *transportModeImageView;

@end
