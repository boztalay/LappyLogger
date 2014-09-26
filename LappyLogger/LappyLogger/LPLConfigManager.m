//
//  LPLConfigManager.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/23/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLConfigManager.h"

#define kDotDirectoryName @".LappyLogger"
#define kConfigPlistName @"config.plist"

#define kDefaultTimedDataSourceInterval 60.0f
#define kDefaultLogDataDirectoryName @"logData"

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
        self.dotDirectoryPath = [[@"~" stringByAppendingPathComponent:kDotDirectoryName] stringByExpandingTildeInPath];
        self.configPlistPath = [self.dotDirectoryPath stringByAppendingPathComponent:kConfigPlistName];
    }
    return self;
}

#pragma mark - Reading the configuration

- (BOOL)readConfigAndReturnSuccess
{
    BOOL doesDotDirectoryExist = [self createDirectoryIfNeeded:self.dotDirectoryPath];
    if(!doesDotDirectoryExist) {
        NSLog(@"Dot directory doesn't exist!");
        return NO;
    }
    NSLog(@"Dot directory does exist");
    
    BOOL didSucessfullyReadConfigPlist = [self readOrCreateConfigPlist];
    if(!didSucessfullyReadConfigPlist) {
        NSLog(@"Config plist is bad!");
        return NO;
    }
    NSLog(@"Config plist is good!");
    
    return YES;
}

- (BOOL)readOrCreateConfigPlist
{
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.configPlistPath
                                                       isDirectory:&isDirectory];

    if(isDirectory) {
        NSLog(@"Config plist was a directory? Deleting it");
        [[NSFileManager defaultManager] removeItemAtPath:self.configPlistPath error:NULL];
    }

    if(!exists || isDirectory) {
        NSLog(@"Attempting to make a config plist with the default values");
        return [self createConfigPlistWithDefaultValues];
    } else {
        NSLog(@"Reading in the config plist");
        return [self readConfigPlist];
    }
}

- (BOOL)createConfigPlistWithDefaultValues
{
    NSDictionary* defaultConfigValues = @{LPLConfigTimedDataSourceIntervalKey : [NSNumber numberWithFloat:kDefaultTimedDataSourceInterval],
                                          LPLConfigLogDataDirectoryKey : [self.dotDirectoryPath stringByAppendingPathComponent:kDefaultLogDataDirectoryName]};
    
    BOOL successfullyWroteConfigPlist = [defaultConfigValues writeToURL:[NSURL fileURLWithPath:self.configPlistPath] atomically:NO];
    if(!successfullyWroteConfigPlist) {
        NSLog(@"Writing the config plist failed!");
        return NO;
    }
    NSLog(@"Writing the config plist succeeded, processing the values");
    
    return [self processConfigValues:defaultConfigValues];
}

- (BOOL)readConfigPlist
{
    NSDictionary* configValues = [[NSDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.configPlistPath]];
    if(configValues == nil) {
        NSLog(@"Reading the config plist failed!");
        return NO;
    }
    NSLog(@"Reading the config plist succeeded, processing the values");
    
    return [self processConfigValues:configValues];
}

- (BOOL)processConfigValues:(NSDictionary*)configValues
{
    self.configValues = configValues;
    
    if(!self.configValues[LPLConfigLogDataDirectoryKey] || !self.configValues[LPLConfigTimedDataSourceIntervalKey]) {
        NSLog(@"Not all of the required fields are present in the config file!");
        return NO;
    }
    
    BOOL doesLogDataDirectoryExist = [self createDirectoryIfNeeded:self.configValues[LPLConfigLogDataDirectoryKey]];
    if(!doesLogDataDirectoryExist) {
        NSLog(@"Creating the log data directory failed!");
        return NO;
    }
    
    NSLog(@"Processing the config file values succeeded");
    
    return YES;
}

#pragma mark - Misc

- (BOOL)createDirectoryIfNeeded:(NSString*)directoryPath
{
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:directoryPath
                                                       isDirectory:&isDirectory];
    if(exists && isDirectory) {
        NSLog(@"Directory %@ already exists", directoryPath);
        return YES;
    } else {
        NSLog(@"Attempting to create directory %@", directoryPath);
        return [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

@end
