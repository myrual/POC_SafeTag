//
//  AppDelegate.h
//  POC_bluetooth
//
//  Created by Wei-Kun Lu (RD-TW) on 13/5/6.
//  Copyright (c) 2013年 Wei-Kun Lu (RD-TW). All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

-(void) playSiren;
-(void) pauseSiren;

@end
