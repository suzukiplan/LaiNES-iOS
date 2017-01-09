//
//  AppDelegate.m
//  LaiNES
//
//  Created by Yoji Suzuki on 2017/01/06.
//  Copyright © 2017年 SUZUKI PLAN. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (readwrite) GCController *controller;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(controllerDidConnect)
                   name:GCControllerDidConnectNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(controllerDidDisconnect)
                   name:GCControllerDidDisconnectNotification
                 object:nil];
    return YES;
}

-(void)controllerDidConnect {
    NSLog(@"GameController did connected");
}

-(void)controllerDidDisconnect {
    NSLog(@"GameController did disconnected");
}

- (void)setupControllers:(NSNotification *)notification
{
    NSArray<GCController*>* contollers = [GCController controllers];
    if (0 < contollers.count) {
        self.controller = contollers[0];
    } else {
        self.controller = nil;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
