//
//  LPLBatteryPercentageDataSource.h
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLDataSource.h"

@interface LPLBatteryPercentageDataSource : LPLDataSource

@property (nonatomic) CGFloat lastBatteryPercentage;

@end
