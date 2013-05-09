//
//  BPXLBluetoothController.m
//  BluetoothBaseStation
//
//  Created by Brandon Alexander on 5/3/13.
//  Copyright (c) 2013 Black PIxel. All rights reserved.
//

#import "BPXLBluetoothController.h"

#import <IOBluetooth/IOBluetooth.h>

static NSString * const kServiceUUID = @"83a871f0-b799-11e2-9e96-0800200c9a66";
static NSString * const kAccelerometerCharacteristicUUID = @"8a218cb0-b799-11e2-9e96-0800200c9a66";

@interface BPXLBluetoothController()<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBUUID *peripheralUUID;
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;

@end

@implementation BPXLBluetoothController

- (instancetype) init {
	self = [super init];
	
	if(self) {
		_peripheralUUID = [CBUUID UUIDWithString:kServiceUUID];
	}
	
	return self;
}

- (void) startScan {
	self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
	self.scanning = YES;
}

- (void) stopScan {
	[self.centralManager stopScan];
	self.centralManager = nil;
	self.scanning = NO;
}

#pragma mark - Central Manager Delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
	if(central.state == CBCentralManagerStateUnauthorized || central.state == CBCentralManagerStateUnsupported)	{
		NSLog(@"Ummmm, this shouldn't have happened");
		return;
	}
	
	if(central.state != CBCentralManagerStatePoweredOn)	{
		NSLog(@"Bluetooth isn't on");
		return;
	}
	
	[self.centralManager scanForPeripheralsWithServices:@[self.peripheralUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
	
	NSLog(@"All systems are a go");
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
	
	// Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        return;
    }
	
    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
//    if (RSSI.integerValue < -35) {
//        return;
//    }
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
	
	if(peripheral != self.connectedPeripheral) {
		[self.centralManager stopScan];
		self.connectedPeripheral = peripheral;
		[self.centralManager connectPeripheral:peripheral options:nil];
	}
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
	
	// Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
	[self.delegate bluetoothControllerDidConnect:self];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
	NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
	self.connectedPeripheral = nil;
	[self.delegate bluetoothControllerDidDisconnect:self];
}

#pragma mark - Peripheral Delegate Methods
/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
//        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kAccelerometerCharacteristicUUID]] forService:service];
    }
}

/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
//        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kAccelerometerCharacteristicUUID]]) {
			
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
			NSLog(@"Subscribed");
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}

/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kAccelerometerCharacteristicUUID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
//		[peripheral readValueForCharacteristic:characteristic];
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
	if(characteristic.value) {
		NSData *rawData = characteristic.value;
//		float *rawBytes = (float *)[rawData bytes];
//		
//		float x = rawBytes[0];
//		float y = rawBytes[1];
//		float z = rawBytes[2];
		float *rawBytes = (float *)[rawData bytes];
		
		float x = *rawBytes;
		rawBytes += 1;
		float y = *rawBytes;
		rawBytes += 1;
		float z = *rawBytes;
		NSLog(@"Data received: %@", rawData);
		NSLog(@"Data received: x: %f y: %f z: %f", x, y, z);
		[self.delegate bluetoothController:self didReceivedXValue:x yValue:y andZValue:z];
//		[peripheral readValueForCharacteristic:characteristic];
	}
}

@end
