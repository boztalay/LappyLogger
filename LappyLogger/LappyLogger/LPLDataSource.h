//
//  LPLDataSource.h
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLLogFileWriter.h"
#import "LPLDataTranslator.h"

@interface LPLDataSource : NSObject

@property (strong, nonatomic) LPLLogFileWriter* logFileWriter;
@property (strong, nonatomic) id<LPLDataTranslator> dataTranslator;

- (BOOL)initializeDataSourceWithName:(NSString*)dataSourceName
                      andLogFileName:(NSString*)logFileName
                   andDataTranslator:(id<LPLDataTranslator>)dataTranslator;
- (void)recordDataPoint;

@end
