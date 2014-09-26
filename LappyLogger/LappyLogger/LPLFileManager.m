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
#define kMagicNumberLength 4 // Probably a better way to do this
#define kVersionNumber "\x01"

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
            NSLog(@"Valid file doesn't exist for file name %@!", fileName);
            return nil;
        }
        NSLog(@"Valid file does exist for file name %@", fileName);
    }
    return self;
}

- (BOOL)validateOrCreateFile:(NSString*)fileName
{
    self.filePath = [[LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey] stringByAppendingPathComponent:fileName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:NULL];

    if(!fileExists) {
        NSLog(@"File %@ is empty or doesn't exist, making it", fileName);
        
        BOOL newFileExists = [self createNewLogFile];
        if(!newFileExists) {
            NSLog(@"Couldn't make file %@!", fileName);
            return NO;
        }
    } else {
        NSLog(@"File %@ exists, validating it", fileName);
        
        NSData* fileContents = [NSData dataWithContentsOfFile:self.filePath];
        BOOL fileContentsAreValid = [self validateFileContents:fileContents];
        if(!fileContentsAreValid) {
            NSLog(@"File %@ isn't valid!", fileName);
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)createNewLogFile
{
    NSMutableData* newFileData = [[NSMutableData alloc] init];
    
    [newFileData appendBytes:kMagicNumber length:kMagicNumberLength];
    [newFileData appendBytes:kVersionNumber length:1];
    [newFileData appendBytes:[self.dataSourceName cStringUsingEncoding:NSUTF8StringEncoding] length:self.dataSourceName.length + 1];

    // Sanity check
    BOOL fileContentsAreValid = [self validateFileContents:newFileData];
    if(!fileContentsAreValid) {
        NSLog(@"New file isn't valid!");
        return NO;
    }
    
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
    char* magicNumber = malloc((kMagicNumberLength + 1) * sizeof(char));
    [fileContents getBytes:magicNumber range:NSMakeRange(0, kMagicNumberLength)];
    magicNumber[kMagicNumberLength] = '\0';
    BOOL magicNumberIsCorrect = (strcmp(magicNumber, kMagicNumber) == 0);
    
    char* versionNumber = malloc(1 * sizeof(char));
    [fileContents getBytes:versionNumber range:NSMakeRange(4, 1)];
    BOOL versionNumberIsCorrect = (strcmp(versionNumber, kVersionNumber) == 0);
    
    free(magicNumber);
    free(versionNumber);
    
    return (magicNumberIsCorrect && versionNumberIsCorrect);
}

#pragma mark - Writing new datapoints to the file

- (BOOL)appendDatapointAndReturnSuccess:(NSData*)datapoint
{
    //TODO
    return YES;
}

@end
