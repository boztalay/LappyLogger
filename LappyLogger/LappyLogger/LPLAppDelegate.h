//
//  LPLAppDelegate.h
//  LappyLogger
//
//  Created by Ben Oztalay on 1/7/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface LPLAppDelegate : NSObject <NSApplicationDelegate>

@property int argc;
@property const char** argv;

- (void)setArgc:(int)argc andArgv:(const char**)argv;

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification;

@end
