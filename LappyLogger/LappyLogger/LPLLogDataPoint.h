//
//  LPLLogDataPoint.h
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPLLogDataPoint : NSObject

@property (nonatomic) unsigned int timestamp;
@property (strong, nonatomic) id data;

@end