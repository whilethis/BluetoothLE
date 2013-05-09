//
//  BPXLViewController.m
//  BluetoothPeripheral
//
//  Created by Brandon Alexander on 5/3/13.
//  Copyright (c) 2013 Black Pixel. All rights reserved.
//

#import "BPXLViewController.h"
#import "BPXLBluetoothBroadcastController.h"
#import <CoreMotion/CoreMotion.h>

@interface BPXLViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (strong, nonatomic) BPXLBluetoothBroadcastController *broadcastController;
@property (weak, nonatomic) IBOutlet UILabel *xLabel;
@property (weak, nonatomic) IBOutlet UILabel *yLabel;
@property (weak, nonatomic) IBOutlet UILabel *zLabel;

@property (strong, nonatomic) CMMotionManager *motionManager;

@end

@implementation BPXLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.broadcastController = [BPXLBluetoothBroadcastController new];
	
	self.motionManager = [[CMMotionManager alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startStopButtonPressed:(id)sender {
	if(self.broadcastController.isBroadcasting) {
		[self.broadcastController stopBroadcasting];
		[self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
		[self.motionManager stopAccelerometerUpdates];
	} else {
		[self.broadcastController startBroadcasting];
		[self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				self.xLabel.text = [NSString stringWithFormat:@"X: %f", accelerometerData.acceleration.x];
				self.yLabel.text = [NSString stringWithFormat:@"Y: %f", accelerometerData.acceleration.y];
				self.zLabel.text = [NSString stringWithFormat:@"Z: %f", accelerometerData.acceleration.z];
				
				[self.broadcastController sendAccelorometerDataWithX:accelerometerData.acceleration.x andY:accelerometerData.acceleration.y andZ:accelerometerData.acceleration.z];
			});
		}];
	}
}

@end
