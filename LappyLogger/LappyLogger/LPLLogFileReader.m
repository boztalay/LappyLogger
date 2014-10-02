//
//  LPLLogFileReader.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogFileReader.h"
#import "LPLConfigManager.h"
#import "LPLLogDataPoint.h"

@interface LPLLogFileReader()

@property (strong, nonatomic) NSMutableArray* unvalidatedDataPoints;

@end

@implementation LPLLogFileReader

- (id)initWithFileName:(NSString *)fileName andDataTranslator:(id<LPLDataTranslator>)dataTranslator
{
    self = [super init];
    if(self) {
        self.dataTranslator = dataTranslator;
        self.logFileHeader = [[LPLLogFileHeader alloc] init];
        self.unvalidatedDataPoints = [[NSMutableArray alloc] init];
        
        BOOL isFileValid = [self readAndValidateFile];
        if(!isFileValid) {
            [self.unvalidatedDataPoints removeAllObjects];
            return nil;
        }
    }
    return self;
}

- (BOOL)readAndValidateFile
{
    return YES;
}

@end
