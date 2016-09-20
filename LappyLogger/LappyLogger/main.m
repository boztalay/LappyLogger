//
//  main.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/19/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLAppDelegate.h"

extern int _CGSDefaultConnection();

int main(int argc, const char* argv[]) {
    @autoreleasepool {
        LPLAppDelegate* delegate = [[LPLAppDelegate alloc] init];
        [delegate setArgc:argc andArgv:argv];

        if(_CGSDefaultConnection() == 0) {
            NSLog(@"LappyLogger: Looks like the window server isn't up yet, restarting...");
            return 0;
        }
        
        NSApplication* application = [NSApplication sharedApplication];
        [application setDelegate:delegate];
        [NSApp run];
    }

    return 1;
}
