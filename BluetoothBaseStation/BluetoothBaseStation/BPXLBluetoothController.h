//
//  BPXLBluetoothController.h
//  BluetoothBaseStation
//
//  Created by Brandon Alexander on 5/3/13.
//  Copyright (c) 2013 Black PIxel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BPXLBluetoothController;

@protocol BPXLBluetoothControllerDelegate <NSObject>

- (void) bluetoothController:(BPXLBluetoothController *)controller didReceivedXValue:(float) xValue yValue:(float) yValue andZValue:(float) zValue;

- (void) bluetoothControllerDidConnect:(BPXLBluetoothController *)controller;
- (void) bluetoothControllerDidDisconnect:(BPXLBluetoothController *)controller;

@end

@interface BPXLBluetoothController : NSObject

@property (nonatomic, getter = isScanning) BOOL scanning;
@property (nonatomic, weak) id<BPXLBluetoothControllerDelegate> delegate;

- (void) startScan;
- (void) stopScan;

@end
