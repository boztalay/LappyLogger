//
//  LPLDataSource.h
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLLogFileManager.h"
#import "LPLDataTranslator.h"

@interface LPLDataSource : NSObject

@property (strong, nonatomic) LPLLogFileManager* fileManager;
@property (strong, nonatomic) id<LPLDataTranslator> dataTranslator;

- (void)recordDataPoint;

@end
