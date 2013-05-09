//
//  BPXLBluetoothBroadcastController.h
//  BluetoothPeripheral
//
//  Created by Brandon Alexander on 5/3/13.
//  Copyright (c) 2013 Black Pixel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPXLBluetoothBroadcastController : NSObject

@property (nonatomic, getter = isBroadcasting) BOOL broadcasting;

- (void) startBroadcasting;
- (void) stopBroadcasting;

- (void) sendAccelorometerDataWithX:(float) x andY:(float) y andZ:(float) z;

@end
