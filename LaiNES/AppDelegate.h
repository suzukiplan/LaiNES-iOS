//
//  AppDelegate.h
//  LaiNES
//
//  Created by Yoji Suzuki on 2017/01/06.
//  Copyright © 2017年 SUZUKI PLAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameController/GameController.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (readonly) GCController *controller;
@end

