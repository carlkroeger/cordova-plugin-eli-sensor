
#import <CoreMotion/CoreMotion.h>
#import "CDVEliSensor.h"

@interface CDVEliSensor () {}
@property (readwrite, assign) BOOL isRunning;
@property (readwrite, assign) BOOL haveReturnedResult;
@property (readwrite, strong) CMMotionManager* motionManager;
@property (readwrite, assign) double x;
@property (readwrite, assign) double y;
@property (readwrite, assign) double z;
@property (readwrite, assign) NSTimeInterval timestamp;
@end

@implementation CDVEliSensor

@synthesize callbackId, isRunning, x, y, z, timestamp;

// defaults to 10 msec
#define kAccelerometerInterval 10

- (CDVEliSensor*)init
{
    self = [super init];
    if (self) {
        self.x = 0;
        self.y = 0;
        self.z = 0;
        self.timestamp = 0;
        self.callbackId = nil;
        self.isRunning = NO;
        self.haveReturnedResult = YES;
        self.motionManager = nil;
    }
    return self;
}

- (void)dealloc
{
    [self stop:nil];
}

- (void)start:(CDVInvokedUrlCommand*)command
{
    self.haveReturnedResult = NO;
    self.callbackId = command.callbackId;

    if (!self.motionManager)
    {
        self.motionManager = [[CMMotionManager alloc] init];
    }

    if ([self.motionManager isSensorAvailable] == YES) {
        // Assign the update interval to the motion manager and start updates
        [self.motionManager setSensorUpdateInterval:kAccelerometerInterval/1000];
        __weak CDVEliSensor* weakSelf = self;
        [self.motionManager startSensorUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMSensorData *sensorData, NSError *error) {
            weakSelf.x = sensorData.rotationRate.x;
            weakSelf.y = sensorData.rotationRate.y;
            weakSelf.z = sensorData.rotationRate.z;
            weakSelf.timestamp = ([[NSDate date] timeIntervalSince1970] * 1000);
            [weakSelf returnSensorInfo];
        }];

        if (!self.isRunning) {
            self.isRunning = YES;
        }
    } else {

        NSLog(@"Running in Simulator? All sensor tests will fail.");
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Error. EliSensor Not Available."];

        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }

}

- (void)onReset
{
    [self stop:nil];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    if ([self.motionManager isSensorAvailable] == YES) {
        if (self.haveReturnedResult == NO) {
            // block has not fired before stop was called, return whatever result we currently have
            [self returnSensorInfo];
        }
        [self.motionManager stopSensorUpdates];
    }
    self.isRunning = NO;
}

- (void)returnSensorInfo
{
    // Create an orientation object
    NSMutableDictionary* orientationProps = [NSMutableDictionary dictionaryWithCapacity:4];

    [orientationProps setValue:[NSNumber numberWithDouble:x] forKey:@"x"];
    [orientationProps setValue:[NSNumber numberWithDouble:y] forKey:@"y"];
    [orientationProps setValue:[NSNumber numberWithDouble:z] forKey:@"z"];
    [orientationProps setValue:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:orientationProps];
    [result setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    self.haveReturnedResult = YES;
}

@end
