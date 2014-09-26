//
//  LPLDataSource.h
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLFileManager.h"

@interface LPLDataSource : NSObject

@property (strong, nonatomic) LPLFileManager* fileManager;

- (void)recordDataPoint;

@end
