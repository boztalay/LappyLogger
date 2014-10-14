//
//  LPLConfigManager.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/23/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLConfigManager.h"
#import "LPLLogger.h"
#include <SystemConfiguration/SystemConfiguration.h>

#define kLoggingPrefix @"LPLConfigManager"

#define kDotDirectoryName @".LappyLogger"
#define kConfigPlistName @"config.plist"

#define kDefaultTimedDataSourceInterval 60.0f
#define kDefaultLogDataDirectoryName @"logData"
#define kDefaultExportDirectoryName @"LappyLoggerData"

@implementation LPLConfigManager

#pragma mark - Init

+ (LPLConfigManager*)sharedInstance
{
    static LPLConfigManager* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LPLConfigManager alloc] init];
    });
    
    return instance;
}

- (id)init
{
    self = [super init];
    if(self) {
        self.homeDirectory = [self getLoggedInUserHomeDirectory];
        if(self.homeDirectory == nil) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't get the current user's home directory, falling back on ~"];
            self.homeDirectory = [@"~" stringByExpandingTildeInPath];
        }
        
        self.dotDirectoryPath = [self.homeDirectory stringByAppendingPathComponent:kDotDirectoryName];
        self.configPlistPath = [self.dotDirectoryPath stringByAppendingPathComponent:kConfigPlistName];
    }
    return self;
}

- (NSString*)getLoggedInUserHomeDirectory
{
    SCDynamicStoreRef store;
    CFStringRef name;
    uid_t uid;
    
    store = SCDynamicStoreCreate(NULL, CFSTR("GetConsoleUser"), NULL, NULL);
    if(store == NULL) {
        return nil;
    }
    
    name = SCDynamicStoreCopyConsoleUser(store, &uid, NULL);
    CFRelease(store);
    
    if(name == NULL) {
        return nil;
    } else {
        return [@"/Users" stringByAppendingPathComponent:(__bridge NSString*)name];
    }
}

#pragma mark - Reading the configuration

- (BOOL)readConfigAndReturnSuccess
{
    BOOL doesDotDirectoryExist = [self createDirectoryIfNeeded:self.dotDirectoryPath];
    if(!doesDotDirectoryExist) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Dot directory doesn't exist!"];
        return NO;
    }
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Dot directory does exist"];
    
    BOOL didSucessfullyReadConfigPlist = [self readOrCreateConfigPlist];
    if(!didSucessfullyReadConfigPlist) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Config plist is bad!"];
        return NO;
    }
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Config plist is good!"];
    
    return YES;
}

- (BOOL)readOrCreateConfigPlist
{
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.configPlistPath
                                                       isDirectory:&isDirectory];

    if(isDirectory) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Config plist was a directory? Deleting it"];
        [[NSFileManager defaultManager] removeItemAtPath:self.configPlistPath error:NULL];
    }

    if(!exists || isDirectory) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Attempting to make a config plist with the default values"];
        return [self createConfigPlistWithDefaultValues];
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading in the config plist"];
        return [self readConfigPlist];
    }
}

- (BOOL)createConfigPlistWithDefaultValues
{
    NSDictionary* defaultConfigValues = @{LPLConfigTimedDataSourceIntervalKey : [NSNumber numberWithFloat:kDefaultTimedDataSourceInterval],
                                          LPLConfigLogDataDirectoryKey : [self.dotDirectoryPath stringByAppendingPathComponent:kDefaultLogDataDirectoryName],
                                          LPLConfigExportDirectoryKey : [self.homeDirectory stringByAppendingPathComponent:kDefaultExportDirectoryName]};
    
    BOOL successfullyWroteConfigPlist = [defaultConfigValues writeToURL:[NSURL fileURLWithPath:self.configPlistPath] atomically:NO];
    if(!successfullyWroteConfigPlist) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Writing the config plist failed!"];
        return NO;
    }
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Writing the config plist succeeded, processing the values"];
    
    return [self processConfigValues:defaultConfigValues];
}

- (BOOL)readConfigPlist
{
    NSDictionary* configValues = [[NSDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.configPlistPath]];
    if(configValues == nil) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading the config plist failed!"];
        return NO;
    }
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading the config plist succeeded, processing the values"];
    
    return [self processConfigValues:configValues];
}

- (BOOL)processConfigValues:(NSDictionary*)configValues
{
    self.configValues = configValues;
    
    if(!self.configValues[LPLConfigLogDataDirectoryKey] || !self.configValues[LPLConfigTimedDataSourceIntervalKey] || !self.configValues[LPLConfigExportDirectoryKey]) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Not all of the required fields are present in the config file!"];
        return NO;
    }
    
    BOOL doesLogDataDirectoryExist = [self createDirectoryIfNeeded:self.configValues[LPLConfigLogDataDirectoryKey]];
    if(!doesLogDataDirectoryExist) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Creating the log data directory failed!"];
        return NO;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Processing the config file values succeeded"];
    
    return YES;
}

#pragma mark - Misc

- (BOOL)createDirectoryIfNeeded:(NSString*)directoryPath
{
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:directoryPath
                                                       isDirectory:&isDirectory];
    if(exists && isDirectory) {
        return YES;
    } else {
        return [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

@end
