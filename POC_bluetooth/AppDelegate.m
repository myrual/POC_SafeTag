//
//  AppDelegate.m
//  POC_bluetooth
//
//  Created by Wei-Kun Lu (RD-TW) on 13/5/6.
//  Copyright (c) 2013年 Wei-Kun Lu (RD-TW). All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@implementation AppDelegate{
    UIBackgroundTaskIdentifier bgTask;
    
    AVAudioPlayer *avPlayer;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //NSString *sirenSound = [[NSBundle mainBundle] pathForResource:@"Siren" ofType:@"wav"];
    NSString *sirenSound = [[NSBundle mainBundle] pathForResource:@"DSPLDETH" ofType:@"WAV"];
    NSURL *url = [NSURL fileURLWithPath:sirenSound];
    NSError *err;
    
    avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    if (avPlayer == nil){
        NSLog(@"%@", [err description]);
    }else{
        
        //to run in the background
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        // Initialize audio session
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        
        NSError *setCategoryErr = nil;
        NSError *activationErr  = nil;
        
        // Active your audio session
        [audioSession setActive:YES error: &activationErr];
        
        // Set audio session category
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryErr];
        
        [avPlayer prepareToPlay];
    }
    
    avPlayer.NumberOfLoops = 0;
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                             bundle: nil];
    ViewController *controller = (ViewController*)[mainStoryboard
                                                   instantiateViewControllerWithIdentifier: @"ViewController"];
    controller.avPlayer = avPlayer;
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if(bgTask == UIBackgroundTaskInvalid)
    {
        UIApplication* app = [UIApplication sharedApplication];
        
        // 開啟了BackgroundTask就要以令以下的queue在Background/Foreground Task都可以運行
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"System Expiration End Background Task");
            [app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
            
        }];
        
        // Start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"prepare local notification");
            
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                                     bundle: nil];
            ViewController *controller = (ViewController*)[mainStoryboard
                                                           instantiateViewControllerWithIdentifier: @"ViewController"];
            [controller notificationCall];
            
            //[app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
            
        });
    }

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [avPlayer pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void) playSiren{
    [avPlayer play];
}

-(void) pauseSiren{
    [avPlayer pause];
}

@end
