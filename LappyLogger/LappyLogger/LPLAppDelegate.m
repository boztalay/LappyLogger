//
//  LPLAppDelegate.m
//  LappyLogger
//
//  Created by Ben Oztalay on 1/7/16.
//  Copyright © 2016 Ben Oztalay. All rights reserved.
//

#import "LPLAppDelegate.h"
#import "LPLLappyLogger.h"

BOOL checkAccessibility() {
    NSDictionary* opts = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    return AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)opts);
}

@implementation LPLAppDelegate

- (void)setArgc:(int)argc andArgv:(const char**)argv {
    self.argc = argc;
    self.argv = argv;
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    if (checkAccessibility()) {
        NSLog(@"Accessibility enabled");
    } else {
        NSLog(@"Accessibility disabled, some logging might not work!");
    }

    BOOL couldStart = [[LPLLappyLogger sharedInstance] startWithArgc:self.argc andArgv:self.argv];
    if(!couldStart) {
        NSLog(@"Uh oh! Lappy Logger couldn't start!");
    } else {
        NSLog(@"Lappy Logger started");
    }
}

@end
