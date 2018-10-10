//
//  AppDelegate.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 01-04-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import "AppDelegate.h"
#import "BlindAssist-Swift.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    OnboardingViewController *controller = [[OnboardingViewController alloc] init];
    _window.rootViewController = controller;
    [_window makeKeyAndVisible];

    controller.onDone = ^{
        [self switchToMain];
    };

    return YES;
}

- (void)switchToMain {
    _window.rootViewController = [[MainViewController alloc] init];
}

@end
