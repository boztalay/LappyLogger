//
//  LPLConfigManager.h
//  LappyLogger
//
//  Created by Ben Oztalay on 9/23/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* LPLConfigLogDataDirectoryKey = @"LogDataDirectory";
static NSString* LPLConfigTimedDataSourceIntervalKey = @"TimedDataSourceInterval";
static NSString* LPLConfigExportDirectoryKey = @"ExportDirectory";

@interface LPLConfigManager : NSObject

@property (strong, nonatomic) NSString* homeDirectory;
@property (strong, nonatomic) NSString* dotDirectoryPath;
@property (strong, nonatomic) NSString* configPlistPath;
@property (strong, nonatomic) NSDictionary* configValues;

+ (LPLConfigManager*)sharedInstance;

- (BOOL)readConfigAndReturnSuccess;

@end
