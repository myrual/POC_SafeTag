//
//  ViewController.m
//  POC_bluetooth
//
//  Created by Wei-Kun Lu (RD-TW) on 13/5/6.
//  Copyright (c) 2013年 Wei-Kun Lu (RD-TW). All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()

@end

@implementation ViewController
{
    UIImage *connectingImg, *connectedImg, *state1Img, *state2Img, *state3Img;
    
    NSMutableArray *datas;
    
    int selectedIndex;
    
    UIView *maskView;
    
    int failCount;
    
    SystemSoundID audioEffect;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.sensor = [[SerialGATT alloc] init];
    [self.sensor setup];
    self.sensor.delegate = self;
    
    datas = [[NSMutableArray alloc] init];
    selectedIndex = -1;
    
    failCount = 0;
    
    const float width = 52.0f;
    const float height = 65.0f;
    
    UIImage *map = [UIImage imageNamed:@"doomfaces"];
    
    connectingImg = [self imageFromImage:map  inRect:CGRectMake(0, 0, width, height)];
    
    UIImage *init1Img = [self imageFromImage:map  inRect:CGRectMake(159, 0, width, height)];
    UIImage *init2Img = [self imageFromImage:map  inRect:CGRectMake(210, 0, width, height)];
    UIImage *init3Img = [self imageFromImage:map  inRect:CGRectMake(262, 0, width, height)];
    
    connectedImg = [self imageFromImage:map  inRect:CGRectMake(53, 332, width, height)];
    
    state1Img = [self imageFromImage:map  inRect:CGRectMake(0, 200, width, height)];
    state2Img = [self imageFromImage:map  inRect:CGRectMake(0, 266, width, height)];
    state3Img = [self imageFromImage:map  inRect:CGRectMake(0, 332, width, height)];
    
    NSArray *eyeFrames = [NSArray array];
    eyeFrames = [[NSArray alloc] initWithObjects: init1Img, init2Img, init3Img, nil];    
    self.signalFaceView.animationImages = eyeFrames;
    self.signalFaceView.animationDuration = 1;
    self.signalFaceView.animationRepeatCount = -1;
    self.signalFaceView.startAnimating;
    
    self.hpLabel.text = @"HP:";
    self.lifeLabel.text = @"Life:";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark tableview datasource delegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [datas count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    
    selectedIndex = row;
    
    [self showMaskView:YES];
    
    dispatch_queue_t spinnerQueue = dispatch_queue_create("spinner", NULL);
    dispatch_async(spinnerQueue, ^{
        //[NSThread sleepForTimeInterval:1];
        
        
        CBPeripheral *peripheral = [datas objectAtIndex:row];
        
        NSLog(@"active peripheral....");
        if (self.sensor.activePeripheral && self.sensor.activePeripheral != peripheral) {
            [self.sensor disconnect:self.sensor.activePeripheral];
        }
        
        self.sensor.activePeripheral = peripheral;
        [self.sensor connect:self.sensor.activePeripheral];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self showMaskView:NO];
            
            [self.btTableView reloadData];
            
            
            NSLog(@"start timer....");
            NSTimer *rssiTimer;
            [rssiTimer invalidate];
            rssiTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(checkRSSI:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop]addTimer:rssiTimer forMode:NSDefaultRunLoopMode];
            
        });
    });

}

#pragma mark tableview delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    // Configure the cell
    NSUInteger row = [indexPath row];
    
    CBPeripheral *peripheral = [datas objectAtIndex:row];
    
    cell.textLabel.text = peripheral.name;
    
    if(selectedIndex == row){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.detailTextLabel.text = @"Connected";
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = @"";
    }
    
    return cell;
}

#pragma mark - button actions

- (IBAction)pressedScanButton:(id)sender {
    
    /*
    [datas removeAllObjects];
    
    [self showMaskView:YES];
    
    dispatch_queue_t spinnerQueue = dispatch_queue_create("spinner", NULL);
    dispatch_async(spinnerQueue, ^{
        [NSThread sleepForTimeInterval:1];
        
        [datas addObject:@"TM Safe Tag"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.btTableView reloadData];
            //dispatch_queue_t spinnerQueue = dispatch_queue_create("spinner", NULL);
            dispatch_async(spinnerQueue, ^{
                [NSThread sleepForTimeInterval:1];
                
                [datas addObject:@"Bluetooth headset PT900"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self showMaskView:NO];
                    
                    [self.btTableView reloadData];
                    
                });
            });
            
        });
    });
    */
    NSLog(@"scan....");
    self.scanButton.enabled = NO;
    [self showMaskView:YES];
    if ([self.sensor activePeripheral]) {
        if ([self.sensor.activePeripheral isConnected]) {
            [self.sensor.manager cancelPeripheralConnection:self.sensor.activePeripheral];
            self.sensor.activePeripheral = nil;
        }
    }
    
    if ([self.sensor peripherals]) {
        self.sensor.peripherals = nil;
        [datas removeAllObjects];
        [self.btTableView reloadData];
    }
    
    self.sensor.delegate = self;
    
    [self.sensor findBTSmartPeripherals:5];
    [self showMaskView:NO];
    
    self.signalFaceView.stopAnimating;
    self.signalFaceView.image = connectingImg;
    
    [self playSound:@"DSSSSIT" :@"WAV"];
    self.scanButton.enabled = YES;
}

-(void)notificationCall{
    NSLog(@"notificationCall");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:10];
        
        UILocalNotification* notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"SafeZone has detected the user is beyond of device";
        
        //notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:10];
        
        //notification.userInfo = [NSDictionary dictionaryWithObject:@"Key" forKey:@"Key"];
        //[[UIApplication sharedApplication] scheduleLocalNotification:notification];
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        
        AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate playSiren];
    });
}

-(void) showMaskView:(BOOL) appear{
    
    if(!maskView){
        
        const float maskWidth = 120.;
        const float maskHeight = 100.;
        
        maskView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 -maskWidth/2, self.view.frame.size.height/2 -maskHeight/2, maskWidth, maskHeight)];
        maskView.alpha = 0.8;
        maskView.backgroundColor = [UIColor blackColor];
        
        maskView.layer.cornerRadius = 10.;
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] init];
        indicatorView.center = CGPointMake(maskView.frame.size.width/2, maskView.frame.size.height/2 -10);
        indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [indicatorView startAnimating];
        
        [maskView addSubview:indicatorView];
        
        UILabel *indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, maskView.frame.size.height/2 + 10, maskWidth, 30)];
        indicatorLabel.text = @"Connecting...";
        indicatorLabel.backgroundColor = [UIColor clearColor];
        indicatorLabel.textColor = [UIColor whiteColor];
        [maskView addSubview:indicatorLabel];
        
        [self.view addSubview:maskView];
    }
    
    if(appear){
        [UIApplication.sharedApplication beginIgnoringInteractionEvents];
        maskView.hidden = NO;
    }else{
        [UIApplication.sharedApplication endIgnoringInteractionEvents];
        maskView.hidden = YES;
    }
    
}

-(void) checkRSSI:(id)sender{

    
    CBPeripheral *peripheral = [datas objectAtIndex:selectedIndex];
    [peripheral readRSSI];
    
    if(peripheral){

        int rssi = [peripheral.RSSI integerValue];
        NSLog(@"RSSI: %i", rssi);

        if(-70 > rssi){
            
            if(failCount>6){
                NSLog(@"play");
                AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
                [delegate playSiren];
            }else{
                failCount++;
            }
            
        }else{
            NSLog(@"pause");
            AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [delegate pauseSiren];
            
            failCount = 0;
        }
        
        //updated face
        if(-50 <= rssi){
            self.signalFaceView.image = connectedImg;
        }else if(-70 > rssi){
            self.signalFaceView.image = state3Img;
        }else if(-60 > rssi){
            self.signalFaceView.image = state2Img;
        }else if(-50 > rssi){
            self.signalFaceView.image = state1Img;
        }
        
        
        //update status
        self.hpLabel.text = [NSString stringWithFormat:@"HP:%i", (rssi+100)];
        self.lifeLabel.text = [NSString stringWithFormat:@"Life:%i", 5-failCount];
        
    }else{
        NSLog(@"peripheral is null");
    }

}

#pragma mark - BTSmartSensorDelegate

-(void) peripheralFound:(CBPeripheral *)peripheral
{
    NSLog(@"peripheral coming... %@", peripheral.name);
    [datas addObject:peripheral];
    [self.btTableView reloadData];
}

- (void)viewDidUnload {
    [self setSignalFaceView:nil];
    [self setHpLabel:nil];
    [self setLifeLabel:nil];
    [self setScanButton:nil];
    [super viewDidUnload];
}

- (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect
{
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}

-(void) playSound : (NSString *) fName : (NSString *) ext
{
    NSString *path  = [[NSBundle mainBundle] pathForResource : fName ofType :ext];
    if ([[NSFileManager defaultManager] fileExistsAtPath : path])
    {
        NSURL *pathURL = [NSURL fileURLWithPath : path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &audioEffect);
        AudioServicesPlaySystemSound(audioEffect);
    }
    else
    {
        NSLog(@"error, file not found: %@", path);
    }
}

@end
