//
//  BikeTableViewCell.h
//  DivvyBikeFinder
//
//  Created by David Warner on 6/9/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BikeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *stationLabel;
@property (weak, nonatomic) IBOutlet UILabel *bikesLabel;
@property (weak, nonatomic) IBOutlet UILabel *docksLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@end
