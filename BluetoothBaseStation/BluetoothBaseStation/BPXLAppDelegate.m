//
//  BPXLAppDelegate.m
//  BluetoothBaseStation
//
//  Created by Brandon Alexander on 5/3/13.
//  Copyright (c) 2013 Black Pixel. All rights reserved.
//

#import "BPXLAppDelegate.h"
#import "BPXLBluetoothController.h"
@interface BPXLAppDelegate()<BPXLBluetoothControllerDelegate>
@property (weak) IBOutlet NSButton *startStopButton;
@property (weak) IBOutlet NSTextField *statusTextField;
@property (weak) IBOutlet NSTextField *xTextField;
@property (weak) IBOutlet NSTextField *yTextField;
@property (weak) IBOutlet NSTextField *zTextField;



@property (strong, nonatomic) BPXLBluetoothController *bluetoothController;
@end

@implementation BPXLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.bluetoothController = [BPXLBluetoothController new];
	self.bluetoothController.delegate = self;
}

- (IBAction)startStopClicked:(id)sender {
	if(self.bluetoothController.isScanning) {
		[self.bluetoothController stopScan];
		self.startStopButton.title = @"Start";
	} else {
		[self.bluetoothController startScan];
		self.startStopButton.title = @"Stop";
	}
}

- (void) bluetoothController:(BPXLBluetoothController *)controller didReceivedXValue:(float) xValue yValue:(float) yValue andZValue:(float) zValue {
	self.xTextField.stringValue = [NSString stringWithFormat:@"X: %f", xValue];
	self.yTextField.stringValue = [NSString stringWithFormat:@"Y: %f", yValue];
	self.zTextField.stringValue = [NSString stringWithFormat:@"Z: %f", zValue];
}

- (void) bluetoothControllerDidConnect:(BPXLBluetoothController *)controller {
	self.statusTextField.stringValue = @"Connected";
}

- (void) bluetoothControllerDidDisconnect:(BPXLBluetoothController *)controller {
	self.statusTextField.stringValue = @"Disconnected";
}

@end
