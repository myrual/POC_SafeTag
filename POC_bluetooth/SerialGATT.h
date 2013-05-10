//
//  SerialGATT.h
//  SerialGATT
//
//  Created by BTSmartShield on 6/29/12.
//  Copyright (c) 2012 BTSmartShield.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define SERIAL_PERIPHERAL_SERVICE_UUID      @"FFF0"
#define SERIAL_PERIPHERAL_CHAR_RECV_UUID    @"FFF1"

#define SERIAL_PERIPHERAL_NOTIFY_SERVICE_UUID @"FFE0"
#define SERIAL_PERIPHERAL_CHAR_NOTIFY_UUID  @"FFE1"

@protocol BTSmartSensorDelegate

@optional
- (void) peripheralFound:(CBPeripheral *)peripheral;
- (void) serialGATTCharValueUpdated: (NSString *)UUID value: (NSData *)data;
@end

@interface SerialGATT : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate> {
    
}

@property (nonatomic, assign) id <BTSmartSensorDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *peripherals;
@property (strong, nonatomic) CBCentralManager *manager;
@property (strong, nonatomic) CBPeripheral *activePeripheral;
@property (strong, nonatomic) CBService *serialGATTService; // for SERIAL_PERIPHERAL_SERVICE_UUID
@property (strong, nonatomic) CBCharacteristic *dataRecvrCharacteristic; // for SERIAL_PERIPHERAL_CHAR_RECV_UUID

@property (strong, nonatomic) CBService *serialGATTNotifyService; // for SERIAL_PERIPHERAL_NOTIFY_SERVICE_UUID
@property (strong, nonatomic) CBCharacteristic *dataNotifyCharacteristic; // for SERIAL_PERIPHERAL_CHAR_NOTIFY_UUID

@property (strong, nonatomic) CBUUID *serviceWriteUUID;
@property (strong, nonatomic) CBUUID *serviceNotifyUUID;

#pragma mark - Methods for controlling the Bluetooth Smart Sensor
-(void) setup; //controller setup

-(int) findBTSmartPeripherals:(int)timeout;
-(void) scanTimer: (NSTimer *)timer;

-(void) connect: (CBPeripheral *)peripheral;
-(void) disconnect: (CBPeripheral *)peripheral;

-(void) write:(CBPeripheral *)peripheral data:(NSData *)data;
-(void) read:(CBPeripheral *)peripheral;
-(void) notify:(CBPeripheral *)peripheral on:(BOOL)on;

-(CBService *) findServiceFromUUID: (CBUUID *)UUID p:(CBPeripheral *)peripheral;
-(CBCharacteristic *) findCharacteristicFromUUID: (CBUUID *)UUID p:(CBPeripheral *)peripheral service: (CBService *)service;



@end
