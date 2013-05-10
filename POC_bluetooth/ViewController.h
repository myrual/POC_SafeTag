//
//  ViewController.h
//  POC_bluetooth
//
//  Created by Wei-Kun Lu (RD-TW) on 13/5/6.
//  Copyright (c) 2013年 Wei-Kun Lu (RD-TW). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SerialGATT.h"

@interface ViewController : UIViewController <BTSmartSensorDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIImageView *signalFaceView;
@property (strong, nonatomic) IBOutlet UILabel *hpLabel;
@property (strong, nonatomic) IBOutlet UILabel *lifeLabel;
@property (strong, nonatomic) IBOutlet UIButton *scanButton;

@property (strong, nonatomic) IBOutlet UITableView *btTableView;

@property (assign, nonatomic) AVAudioPlayer *avPlayer;

@property (strong, nonatomic) SerialGATT *sensor;

- (IBAction)pressedScanButton:(id)sender;

-(void) notificationCall;

@end
