//
//  SerialGATT.m
//  SerialGATT
//
//  Created by BTSmartShield on 6/29/12.
//  Copyright (c) 2012 BTSmartShield.com. All rights reserved.
//

#import "SerialGATT.h"

@implementation SerialGATT

@synthesize delegate;
@synthesize peripherals;
@synthesize manager;
@synthesize activePeripheral;

@synthesize serialGATTService;
@synthesize dataRecvrCharacteristic;

@synthesize serialGATTNotifyService;
@synthesize dataNotifyCharacteristic;


@synthesize serviceWriteUUID;
@synthesize serviceNotifyUUID;

/*
 * (void) setup
 * enable CoreBluetooth CentralManager and set the delegate for SerialGATT
 *
 */

-(void) setup
{
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // initialize the Service UUID interested
    serviceWriteUUID = [CBUUID UUIDWithString:SERIAL_PERIPHERAL_SERVICE_UUID];
    serviceNotifyUUID = [CBUUID UUIDWithString:SERIAL_PERIPHERAL_NOTIFY_SERVICE_UUID];
}

/*
 * -(int) findBTSmartPeripherals:(int)timeout
 *
 * search for the BTSmartPeripherals and stop in timeout
 */

-(int) findBTSmartPeripherals:(int)timeout
{
    if ([manager state] != CBCentralManagerStatePoweredOn) {
        printf("CoreBluetooth is not correctly initialized !\n");
        return -1;
    }
    
    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
    //[manager scanForPeripheralsWithServices:[NSArray arrayWithObject:serviceUUID] options:0]; // start Scanning
    [manager scanForPeripheralsWithServices:nil options:0];
    return 0;
}

/*
 * scanTimer
 * when findBTSmartPeripherals is timeout, this function will be called
 *
 */
-(void) scanTimer:(NSTimer *)timer
{
    [manager stopScan];
}

/*
 * connect
 * connect to a given peripheral
 *
 */
-(void) connect:(CBPeripheral *)peripheral
{
    if (![peripheral isConnected]) {
        [manager connectPeripheral:peripheral options:nil];
    }
}

/*
 * disconnect
 * disconnect to a given peripheral
 *
 */
-(void) disconnect:(CBPeripheral *)peripheral
{
    [manager cancelPeripheralConnection:peripheral];
}

#pragma mark - basic operations for SerialGATT service
-(void) write:(CBPeripheral *)peripheral data:(NSData *)data
{
    if (!serialGATTService || !dataRecvrCharacteristic) {
        return;
    }
    
    [peripheral writeValue:data forCharacteristic:dataRecvrCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

-(void) read:(CBPeripheral *)peripheral
{
    if (!serialGATTService || !dataRecvrCharacteristic) {
        return;
    }
    
    [peripheral readValueForCharacteristic:dataRecvrCharacteristic];
}

-(void) notify: (CBPeripheral *)peripheral on:(BOOL)on
{
    if (!serialGATTService || !dataNotifyCharacteristic) {
        return;
    }
    [peripheral setNotifyValue:on forCharacteristic:dataNotifyCharacteristic];
}

#pragma mark - Finding CBServices and CBCharacteristics

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)peripheral
{
    printf("the services count is %d\n", peripheral.services.count);
    for (CBService *s in peripheral.services) {
        // compare s with UUID
        if ([[s.UUID data] isEqualToData:[UUID data]]) {
            return s;
        }
    }
    return  nil;
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID p:(CBPeripheral *)peripheral service:(CBService *)service
{
    for (CBCharacteristic *c in service.characteristics) {
        printf("characteristic <%s> is found!\n", [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
        if ([[c.UUID data] isEqualToData:[UUID data]]) {
            return c;
        }
    }
    return nil;
}


#pragma mark - CBCentralManager Delegates

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    //TODO: to handle the state updates
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!peripherals) {
        peripherals = [[NSMutableArray alloc] initWithObjects:peripheral, nil];
    } else {
        // Add the new peripheral to the peripherals array
        for (int i = 0; i < [peripherals count]; i++) {
            CBPeripheral *p = [peripherals objectAtIndex:i];
            
            if ([p.name isEqualToString:peripheral.name]) {
                [peripherals replaceObjectAtIndex:i withObject:peripheral];
                [delegate peripheralFound:peripheral];
                return;
            }
        }
        printf("New peripheral is found...\n");
        [peripherals addObject:peripheral];
        [delegate peripheralFound:peripheral];
    }
    printf("%s\n", __FUNCTION__);
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    activePeripheral = peripheral;
    activePeripheral.delegate = self;
    
    [activePeripheral discoverServices:nil];
    
    printf("connected to the active peripheral\n");
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    activePeripheral = nil;
    printf("disconnected to the active peripheral\n");
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"failed to connect to peripheral %@: %@\n", [peripheral name], [error localizedDescription]);
}

#pragma mark - CBPeripheral delegates

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        printf("updateValueForCharacteristic failed\n");
        return;
    }

    NSTimer *rssiTimer;
    [rssiTimer invalidate];
    rssiTimer = [NSTimer timerWithTimeInterval:1.0 target:peripheral selector:@selector(readRSSI) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:rssiTimer forMode:NSRunLoopCommonModes];
    
    // Compare the characteristic with SERIAL_PERIPHERAL_CHAR_RECV_UUID and SERIAL_PERIPHERAL_CHAR_NOTIFY_UUID
    CBUUID *charRecvUUID = [CBUUID UUIDWithString:SERIAL_PERIPHERAL_CHAR_RECV_UUID];
    CBUUID *charNotifyUUID = [CBUUID UUIDWithString:SERIAL_PERIPHERAL_CHAR_NOTIFY_UUID];

    if ([[characteristic.UUID data] isEqualToData:[charRecvUUID data]]) {
        // TODO: read the data from SERIAL_PERIPHERAL_CHAR_RECV_UUID, which can be used to write and read data
        [delegate serialGATTCharValueUpdated:SERIAL_PERIPHERAL_CHAR_RECV_UUID value:characteristic.value];
    } else  if ([[characteristic.UUID data] isEqualToData:[charNotifyUUID data]]) {
        // TODO: read the data from SERIAL_PERIPHERAL_CHAR_NOTIFY_UUID
        [delegate serialGATTCharValueUpdated:SERIAL_PERIPHERAL_CHAR_NOTIFY_UUID value:characteristic.value];
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    //NSLog(@"peripheralDidUpdateRSSI gogogo: %@  %@", [error description], peripheral.RSSI);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        printf("The services are found\n");
        serialGATTService = [self findServiceFromUUID:[CBUUID UUIDWithString:SERIAL_PERIPHERAL_SERVICE_UUID] p:peripheral];
        if (!serialGATTService) {
            printf("The desired service is not found!\n");
            return;
        } else {
            [peripheral discoverCharacteristics:nil forService:serialGATTService];
        }
        
        serialGATTNotifyService = [self findServiceFromUUID:[CBUUID UUIDWithString:SERIAL_PERIPHERAL_NOTIFY_SERVICE_UUID] p:peripheral];
        if (!serialGATTNotifyService) {
            printf("The desired service is not found\n");
            return;
        } else {
            [peripheral discoverCharacteristics:nil forService:serialGATTNotifyService];
        }
    }
    else {
        printf("discoverservices is uncesessful!\n");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        printf("The characteristics are found for the service!\n");
        dataRecvrCharacteristic = [self findCharacteristicFromUUID:[CBUUID UUIDWithString:SERIAL_PERIPHERAL_CHAR_RECV_UUID] p:peripheral service:serialGATTService];
        dataNotifyCharacteristic = [self findCharacteristicFromUUID:[CBUUID UUIDWithString:SERIAL_PERIPHERAL_CHAR_NOTIFY_UUID] p:peripheral service:serialGATTNotifyService];
        if (!dataNotifyCharacteristic || !dataRecvrCharacteristic) {
            printf("The desired characteristics can't be found!\n");
            return;
        } else {
            [self notify:peripheral on:YES];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        printf("setting notification\n");
    } else {
        printf("failed\n");
    }
}

@end
