//
//  LappyLogger.h
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPLLappyLogger : NSObject

@property (strong, nonatomic) NSMutableArray* dataSources;
@property (strong, nonatomic) NSTimer* timer;

+ (LPLLappyLogger*)sharedInstance;

- (BOOL)startWithArgc:(int)argc andArgv:(char*[])argv;

@end
