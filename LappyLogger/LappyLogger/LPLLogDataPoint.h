//
//  LPLLogDataPoint.h
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLDataTranslator.h"

@interface LPLLogDataPoint : NSObject

@property (nonatomic) unsigned int timestamp;
@property (strong, nonatomic) id data;
@property (strong, nonatomic) NSData* rawData;

+ (LPLLogDataPoint*)dataPointFromFileContents:(NSData*)fileContents atIndex:(NSUInteger)index withDataTranslator:(id<LPLDataTranslator>)dataTranslator;
+ (LPLLogDataPoint*)dataPointFromTimestamp:(unsigned int)timestamp andData:(id)data withDataTranslator:(id<LPLDataTranslator>)dataTranslator;

@end