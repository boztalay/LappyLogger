//
//  LPLLogFileWriter.h
//  LappyLogger
//
//  Created by Ben Oztalay on 10/3/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLDataTranslator.h"
#import "LPLLogDataPoint.h"

@interface LPLLogFileWriter : NSObject

@property (strong, nonatomic) NSString* filePath;
@property (strong, nonatomic) id<LPLDataTranslator> dataTranslator;

- (id)initWithFileName:(NSString*)fileName
     andDataSourceName:(NSString*)dataSourceName
     andDataTranslator:(id<LPLDataTranslator>)dataTranslator;

- (BOOL)appendDataPointAndReturnSuccess:(id)dataToWrite;

@end
