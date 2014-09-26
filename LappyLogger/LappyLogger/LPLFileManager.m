//
//  LPLFileManager.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLFileManager.h"
#import "LPLConfigManager.h"

#define kMagicNumber "BOLL"
#define kVersionNumber "\x0x01"

// Oh yeah we're doing this custom file format thing

@implementation LPLFileManager

#pragma mark - Init, creating and/or validating the file

- (id)initWithFileName:(NSString*)fileName andDataSourceName:(NSString*)dataSourceName
{
    self = [super init];
    if(self) {
        self.dataSourceName = dataSourceName;
        
        BOOL validFileExists = [self validateOrCreateFile:fileName];
        if(!validFileExists) {
            return nil;
        }
    }
    return self;
}

- (BOOL)validateOrCreateFile:(NSString*)fileName
{
    self.filePath = [[LPLConfigManager sharedInstance].dotDirectoryPath stringByAppendingPathComponent:fileName];
    NSData* fileContents = [NSData dataWithContentsOfFile:self.filePath];
    if(fileContents == nil) {
        return NO;
    }
    
    if(fileContents.length == 0) {
        BOOL newFileExists = [self createNewLogFile];
        if(!newFileExists) {
            return NO;
        }
    } else {
        BOOL fileContentsAreValid = [self validateFileContents:fileContents];
        if(!fileContentsAreValid) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)createNewLogFile
{
    NSMutableData* newFileData = [[NSMutableData alloc] init];
    
    [newFileData appendBytes:kMagicNumber length:(sizeof(kMagicNumber) / sizeof(char))];
    [newFileData appendBytes:kVersionNumber length:1];
    [newFileData appendBytes:[self.dataSourceName cStringUsingEncoding:NSUTF8StringEncoding] length:self.dataSourceName.length];
    
    return [newFileData writeToFile:self.filePath atomically:YES];
}

# pragma mark - Guts of file validation

- (BOOL)validateFileContents:(NSData*)fileContents
{
    BOOL areMagicNumberAndVersionNumberCorrect = [self validateMagicNumberAndVersionNumber:fileContents];
    if(!areMagicNumberAndVersionNumberCorrect) {
        return NO;
    }
    
    //TODO
    
    return YES;
}

- (BOOL)validateMagicNumberAndVersionNumber:(NSData*)fileContents
{
    //TODO
    return YES;
}

#pragma mark - Writing new datapoints to the file

- (BOOL)appendDatapointAndReturnSuccess:(NSData*)datapoint
{
    //TODO
    return YES;
}

@end
