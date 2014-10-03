//
//  LPLLogFileHeader.h
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPLLogFileHeader : NSObject

@property (strong, nonatomic) NSString* magicNumber;
@property (nonatomic) NSUInteger versionNumber;
@property (nonatomic) NSUInteger dataPointLength;
@property (strong, nonatomic) NSString* dataSourceName;
@property (strong, nonatomic) NSData* rawData;

+ (LPLLogFileHeader*)logFileHeaderFromFileContents:(NSData*)fileContents;
+ (LPLLogFileHeader*)logFileHeaderFromDataPointLength:(NSUInteger)dataPointLength andDataSourceName:(NSString*)dataSourceName;

@end
