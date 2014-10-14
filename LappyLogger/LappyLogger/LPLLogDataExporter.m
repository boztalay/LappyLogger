//
//  LPLLogDataExporter.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/12/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogDataExporter.h"
#import "LPLConfigManager.h"
#import "LPLLogFileReader.h"
#import "LPLLogger.h"
#import "LPLDataSource.h"
#import "LPLBatteryPercentageDataSource.h"
#import "LPLBatteryLifeDataSource.h"
#import "LPLACConnectionStatusDataSource.h"
#import "LPLKeystrokesDataSource.h"
#import "LPLMouseClicksDataSource.h"
#import "LPLStartUpsDataSource.h"

#define kLoggingPrefix @"LPLLogDataExporter"
#define kExportFileExtension @"csv"

@implementation LPLLogDataExporter

- (id)init
{
    self = [super init];
    if(self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return self;
}

- (BOOL)exportData
{
    BOOL exportSucceeded = YES;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[LPLConfigManager sharedInstance].configValues[LPLConfigExportDirectoryKey] isDirectory:nil]) {
        BOOL couldCreateExportDirectory = [[NSFileManager defaultManager] createDirectoryAtPath:[LPLConfigManager sharedInstance].configValues[LPLConfigExportDirectoryKey]
                                                                    withIntermediateDirectories:YES attributes:nil error:nil];
        if(!couldCreateExportDirectory) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create the export directory!"];
            return NO;
        }
    }
    
    exportSucceeded = exportSucceeded && [self exportDataFromDataSource:[LPLBatteryLifeDataSource class]];
    exportSucceeded = exportSucceeded && [self exportDataFromDataSource:[LPLBatteryPercentageDataSource class]];
    exportSucceeded = exportSucceeded && [self exportDataFromDataSource:[LPLACConnectionStatusDataSource class]];
    exportSucceeded = exportSucceeded && [self exportDataFromDataSource:[LPLKeystrokesDataSource class]];
    exportSucceeded = exportSucceeded && [self exportDataFromDataSource:[LPLMouseClicksDataSource class]];
    exportSucceeded = exportSucceeded && [self exportDataFromDataSource:[LPLStartUpsDataSource class]];
    
    return exportSucceeded;
}

- (BOOL)exportDataFromDataSource:(Class)DataSourceClass
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Exporting data from %@...", NSStringFromClass(DataSourceClass)];
    [[LPLLogger sharedInstance] incrementIndent];
    
    NSMutableArray* filesFromThisDataSource = [[NSMutableArray alloc] init];
    NSArray* contentsOfLogDataDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey] error:nil];
    for(NSString* fileInLogDataDirectory in contentsOfLogDataDirectory) {
        if([fileInLogDataDirectory hasPrefix:[DataSourceClass fileBaseName]]) {
            [filesFromThisDataSource addObject:fileInLogDataDirectory];
        }
    }
    
    NSArray* sortedFilesFromThisDataSource = [filesFromThisDataSource sortedArrayUsingComparator:^(id a, id b) {
        return [a compare:b options:NSNumericSearch];
    }];
    
    NSMutableArray* fileReaders = [[NSMutableArray alloc] init];
    for(NSString* file in sortedFilesFromThisDataSource) {
        NSString* fullFilePath = [[LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey] stringByAppendingPathComponent:file];
        
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading %@...", file];
        [[LPLLogger sharedInstance] incrementIndent];
        LPLLogFileReader* fileReader = [[LPLLogFileReader alloc] initWithFilePath:fullFilePath andDataTranslator:[DataSourceClass dataTranslator]];
        [[LPLLogger sharedInstance] decrementIndent];
        
        if(fileReader != nil) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading %@ succeeded!", file];
            [fileReaders addObject:fileReader];
        } else {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading %@ failed! Skipping it", file];
        }
    }
    
    if(fileReaders.count <= 0) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Failed to export any data from %@!", NSStringFromClass(DataSourceClass)];
        return NO;
    }
    
    NSMutableArray* dataPointsToExport = [[NSMutableArray alloc] init];
    for(LPLLogFileReader* fileReader in fileReaders) {
        [dataPointsToExport addObjectsFromArray:fileReader.dataPoints];
    }
    
    NSString* exportFileName = [[DataSourceClass fileBaseName] stringByAppendingPathExtension:kExportFileExtension];
    NSString* exportFileFullPath = [[LPLConfigManager sharedInstance].configValues[LPLConfigExportDirectoryKey] stringByAppendingPathComponent:exportFileName];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:exportFileFullPath isDirectory:nil]) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"An export file already exists for %@! Can't export its data", NSStringFromClass(DataSourceClass)];
        return NO;
    }
    
    [[NSFileManager defaultManager] createFileAtPath:exportFileFullPath contents:nil attributes:nil];
    NSFileHandle* exportFile = [NSFileHandle fileHandleForWritingAtPath:exportFileFullPath];
    if(exportFile == nil) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create an export file for %@!", NSStringFromClass(DataSourceClass)];
        return NO;
    }
    
    [exportFile writeData:[@"timestamp,data\n" dataUsingEncoding:NSUTF8StringEncoding]];
    for(LPLLogDataPoint* dataPoint in dataPointsToExport) {
        NSDate* timestampDate = [NSDate dateWithTimeIntervalSinceReferenceDate:dataPoint.timestamp];
        [exportFile writeData:[[NSString stringWithFormat:@"\"%@\",\"%@\"\n", [self.dateFormatter stringFromDate:timestampDate], [dataPoint.data stringValue]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [exportFile closeFile];
    
    [[LPLLogger sharedInstance] decrementIndent];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully exported!"];
    
    return YES;
}

@end
