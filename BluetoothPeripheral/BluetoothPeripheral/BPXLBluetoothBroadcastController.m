//
//  BPXLBluetoothBroadcastController.m
//  BluetoothPeripheral
//
//  Created by Brandon Alexander on 5/3/13.
//  Copyright (c) 2013 Black Pixel. All rights reserved.
//

#import "BPXLBluetoothBroadcastController.h"
#import <CoreBluetooth/CoreBluetooth.h>
static NSString * const kServiceUUID = @"83a871f0-b799-11e2-9e96-0800200c9a66";
static NSString * const kAccelerometerCharacteristicUUID = @"8a218cb0-b799-11e2-9e96-0800200c9a66";

@interface BPXLBluetoothBroadcastController()<CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *service;
@property (nonatomic, strong) CBMutableCharacteristic *transferCharacteristic;
@property (nonatomic, strong) CBUUID *peripheralServiceUUID;
@property (nonatomic, strong) CBUUID *accelerometerCharacteristicUUID;
@property (nonatomic, strong) CBCentral *subscribedCentral;
@property (nonatomic, strong) CBCharacteristic *subscribedCharacteristic;

@property (nonatomic) BOOL readyToSendData;

@property (nonatomic) float queuedXValue;
@property (nonatomic) float queuedYValue;
@property (nonatomic) float queuedZValue;

@end

@implementation BPXLBluetoothBroadcastController

- (instancetype) init {
	self = [super init];
	
	if(self) {
		_peripheralServiceUUID = [CBUUID UUIDWithString:kServiceUUID];
		_accelerometerCharacteristicUUID = [CBUUID UUIDWithString:kAccelerometerCharacteristicUUID];
		_readyToSendData = NO;
	}
	
	return self;
}

- (void) startBroadcasting {
	if(self.peripheralManager.isAdvertising) {
		[self.peripheralManager stopAdvertising];
	}
	
	self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
	self.broadcasting = YES;
}

- (void) stopBroadcasting {
	[self.peripheralManager stopAdvertising];
	
	self.broadcasting = NO;
}

- (void) sendAccelorometerDataWithX:(float) x andY:(float) y andZ:(float) z {
	self.queuedXValue = x;
	self.queuedYValue = y;
	self.queuedZValue = z;
	
	[self sendData];
}

- (void) sendData {
	if(self.readyToSendData) {
		float x = self.queuedXValue;
		float y = self.queuedYValue;
		float z = self.queuedZValue;
		
		NSMutableData *dataToSend = [NSMutableData data];
		[dataToSend appendBytes:&x length:sizeof(x)];
		[dataToSend appendBytes:&y length:sizeof(y)];
		[dataToSend appendBytes:&z length:sizeof(z)];
		
		BOOL success = [self.peripheralManager updateValue:dataToSend forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
		
		if(!success) {
			self.readyToSendData = NO;
//			NSLog(@"Not sending Data");
		} else {
//			NSLog(@"Data sent");
		}
	}
}

#pragma mark - Peripheral Manager Delegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
	if(peripheral.state == CBPeripheralManagerStateUnsupported || peripheral.state == CBPeripheralManagerStateUnauthorized)	{
		NSLog(@"Advertising failed.");
		return;
	}
	
	if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
		NSLog(@"Bluetooth isn't powered up.");
        return;
    }
    
	CBCharacteristicProperties props = CBCharacteristicPropertyNotify;
	
	CBMutableCharacteristic *shareTypeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:self.accelerometerCharacteristicUUID properties:props value:nil permissions:CBAttributePermissionsReadable];
	
	self.transferCharacteristic = shareTypeCharacteristic;
	
	self.service = [[CBMutableService alloc] initWithType:self.peripheralServiceUUID primary:YES];
	self.service.characteristics = @[shareTypeCharacteristic];
	
	[self.peripheralManager addService:self.service];
	[self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[self.peripheralServiceUUID] }];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	self.subscribedCentral = central;
	self.subscribedCharacteristic = characteristic;
	self.readyToSendData = YES;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
	NSLog(@"%s", __PRETTY_FUNCTION__);
}

//- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
//	float x = self.queuedXValue;
//	float y = self.queuedYValue;
//	float z = self.queuedZValue;
//	
//	NSMutableData *dataToSend = [NSMutableData data];
//	[dataToSend appendBytes:&x length:sizeof(x)];
//	[dataToSend appendBytes:&y length:sizeof(y)];
//	[dataToSend appendBytes:&z length:sizeof(z)];
//	
//	request.value = dataToSend;
//	NSLog(@"Data sent: %@", dataToSend);
//	NSLog(@"Data received: x: %f y: %f z: %f", x, y, z);
//	
//	[peripheral respondToRequest:request withResult:CBATTErrorSuccess];
//}
//
//- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
//	
//}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
	self.readyToSendData = YES;
	
	[self sendData];
}
@end
