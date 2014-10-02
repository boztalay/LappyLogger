//
//  LPLLogFileReader.h
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLDataTranslator.h"
#import "LPLLogFileHeader.h"

@interface LPLLogFileReader : NSObject

@property (strong, nonatomic) id<LPLDataTranslator> dataTranslator;
@property (strong, nonatomic) LPLLogFileHeader* logFileHeader;
@property (strong, nonatomic) NSArray* dataPoints;

- (id)initWithFileName:(NSString*)fileName andDataTranslator:(id<LPLDataTranslator>)dataTranslator;

@end
