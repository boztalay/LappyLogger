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
        self.dotDirectoryPath = [@"~" stringByAppendingPathComponent:kDotDirectoryName];
        self.configPlistPath = [self.dotDirectoryPath stringByAppendingPathComponent:kConfigPlistName];
    }
    return self;
}

#pragma mark - Reading the configuration

- (BOOL)readConfigAndReturnSuccess
{
    BOOL doesDotDirectoryExist = [self createDirectoryIfNeeded:self.dotDirectoryPath];
    if(!doesDotDirectoryExist) {
        return NO;
    }
    
    BOOL didSucessfullyReadConfigPlist = [self readOrCreateConfigPlist];
    if(!didSucessfullyReadConfigPlist) {
        return NO;
    }
    
    return YES;
}

- (BOOL)readOrCreateConfigPlist
{
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.configPlistPath
                                                       isDirectory:&isDirectory];

    if(isDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:self.configPlistPath error:NULL];
    }

    if(!exists || isDirectory) {
        return [self createConfigPlistWithDefaultValues];
    } else {
        return [self readConfigPlist];
    }
}

- (BOOL)createConfigPlistWithDefaultValues
{
    NSDictionary* defaultConfigValues = @{LPLConfigTimedDataSourceIntervalKey : [NSNumber numberWithFloat:kDefaultTimedDataSourceInterval],
                                          LPLConfigLogDataDirectoryKey : [self.dotDirectoryPath stringByAppendingPathComponent:kDefaultLogDataDirectoryName]};
    
    BOOL successfullyWroteConfigPlist = [defaultConfigValues writeToURL:[NSURL fileURLWithPath:self.configPlistPath] atomically:NO];
    if(!successfullyWroteConfigPlist) {
        return NO;
    }
    
    return [self processConfigValues:defaultConfigValues];
}

- (BOOL)readConfigPlist
{
    NSDictionary* configValues = [[NSDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.configPlistPath]];
    if(configValues == nil) {
        return NO;
    }
    
    return [self processConfigValues:configValues];
}

- (BOOL)processConfigValues:(NSDictionary*)configValues
{
    self.configValues = configValues;
    
    BOOL doesLogDataDirectoryExist = [self createDirectoryIfNeeded:self.configValues[LPLConfigLogDataDirectoryKey]];
    if(!doesLogDataDirectoryExist) {
        return NO;
    }
    
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
