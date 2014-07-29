//
//  RouteTableViewCell.m
//  DivvyBikeFinder
//
//  Created by David Warner on 7/25/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "RouteTableViewCell.h"

@implementation RouteTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
