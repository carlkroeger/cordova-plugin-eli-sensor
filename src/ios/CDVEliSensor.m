
#import <CoreMotion/CoreMotion.h>
#import "CDVEliSensor.h"

@interface CDVEliSensor () {}
@property (readwrite, assign) BOOL isRunning;
@property (readwrite, assign) BOOL haveReturnedResult;
@property (readwrite, strong) CMMotionManager* motionManager;
@property (readwrite, assign) double x;
@property (readwrite, assign) double y;
@property (readwrite, assign) double z;
@property (readwrite, assign) NSDictionary *sensor_dict;
@property (readwrite, assign) NSMutableDictionary *sensor_list;
@property (readwrite, assign) NSMutableArray *sensor_list2;
@property (readwrite, assign) NSArray *data;
@property (readwrite, assign) int sensor_type;
@property (readwrite, assign) NSTimeInterval timestamp;
@end

@implementation CDVEliSensor

@synthesize callbackId, isRunning, x, y, z, sensor_list, sensor_list2, data, sensor_dict,sensor_type, timestamp;

// defaults to 10 msec
#define kAccelerometerInterval 10

- (CDVEliSensor*)init
{
    self = [super init];
    if (self) {
        self.x = 0;
        self.y = 0;
        self.z = 0;
        self.sensor_dict = @{ @"1" : @"TYPE_ACCELEROMETER", @"4" : @"TYPE_GYROSCOPE",@"15" : @"TYPE_GAME_ROTATION_VECTOR"};
        self.timestamp = 0;
        self.callbackId = nil;
        self.isRunning = NO;
        self.haveReturnedResult = YES;
        self.motionManager = nil;
        self.sensor_list2 = [NSMutableArray array];
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
    NSNumber* s_type = [command.arguments objectAtIndex:0];
    NSLog(@"sensor_type");
    NSLog(@"%@",s_type);
    if (!self.motionManager)
    {
        self.motionManager = [[CMMotionManager alloc] init];
    }
    NSLog(@"motion manager");
    NSLog(@"%@",self.motionManager);
    NSLog(@"fin motion manager");

    if([s_type intValue] == 1){
        if ([self.motionManager isAccelerometerAvailable] == YES) {
                // Assign the update interval to the motion manager and start updates
                [self.motionManager setAccelerometerUpdateInterval:kAccelerometerInterval/1000];  // expected in seconds
                __weak CDVEliSensor* weakSelf = self;
                [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                    weakSelf.x = accelerometerData.acceleration.x;
                    weakSelf.y = accelerometerData.acceleration.y;
                    weakSelf.z = accelerometerData.acceleration.z;
                    weakSelf.data = [[NSArray alloc] initWithObjects:
                                      [NSNumber numberWithFloat:accelerometerData.acceleration.x],
                                      [NSNumber numberWithFloat:accelerometerData.acceleration.y],
                                      [NSNumber numberWithFloat:accelerometerData.acceleration.z],
                                     [NSNumber numberWithInt:([[NSDate date] timeIntervalSince1970] * 1000)], nil];
                    NSArray* array = [[NSArray alloc] initWithObjects:
                                             [NSNumber numberWithFloat:accelerometerData.acceleration.x],
                                             [NSNumber numberWithFloat:accelerometerData.acceleration.y],
                                             [NSNumber numberWithFloat:accelerometerData.acceleration.z],
                                            [NSNumber numberWithInt:([[NSDate date] timeIntervalSince1970] * 1000)], nil];
                    weakSelf.timestamp = ([[NSDate date] timeIntervalSince1970] * 1000);
//                    [weakSelf returnSensorInfo];
                    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:array];
                    [result setKeepCallback:[NSNumber numberWithBool:YES]];
                    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
                    self.haveReturnedResult = YES;
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

    if([s_type intValue] == 4){
        if ([self.motionManager isGyroAvailable] == YES) {
            // Assign the update interval to the motion manager and start updates
            [self.motionManager setGyroUpdateInterval:kAccelerometerInterval/1000];
            __weak CDVEliSensor* weakSelf = self;
            [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMGyroData *sensorData, NSError *error) {
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


}
- (void)sensor_list:(CDVInvokedUrlCommand*)command
{
    NSMutableArray* array = [NSMutableArray new];
    self.callbackId = command.callbackId;
    if (!self.motionManager)
    {
        self.motionManager = [[CMMotionManager alloc] init];
    }

    if ([self.motionManager isGyroAvailable] == YES) {

        NSLog(@"tiene giro");
        NSMutableDictionary* sensor_item = [NSMutableDictionary dictionaryWithCapacity:3];
            [sensor_item setValue:@"Giroscopio" forKey:@"string_type"];
            [sensor_item setValue:[NSNumber numberWithInt:4] forKey:@"type"];
            [sensor_item setValue:@"TYPE_GYROSCOPE" forKey:@"name"];
        [array addObject:sensor_item];
    }
    if ([self.motionManager isDeviceMotionAvailable] == YES) {

        NSLog(@"tiene devicemotion");
        NSMutableDictionary* sensor_item = [NSMutableDictionary dictionaryWithCapacity:3];
            [sensor_item setValue:@"Vector de rotacion" forKey:@"string_type"];
            [sensor_item setValue:[NSNumber numberWithInt:15]  forKey:@"type"];
            [sensor_item setValue:@"TYPE_GAME_ROTATION_VECTOR" forKey:@"name"];
        [array addObject:sensor_item];
    }
    if ([self.motionManager isAccelerometerAvailable] == YES) {

        NSLog(@"tiene accelerometer");
        NSMutableDictionary* sensor_item = [NSMutableDictionary dictionaryWithCapacity:3];
            [sensor_item setValue:@"Acelerometro" forKey:@"string_type"];
            [sensor_item setValue:[NSNumber numberWithInt:1]  forKey:@"type"];
            [sensor_item setValue:@"TYPE_ACCELEROMETER" forKey:@"name"];
        [array addObject:sensor_item];
    }


    NSLog(@"sensor list");
    NSLog(@"%@",array);

//    self.sensor_list = sensor_item;

        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:array];

        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];

    NSLog(@"sensor list fin");
}
- (void)onReset
{
    [self stop:nil];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    if ([self.motionManager isGyroAvailable] == YES) {
        if (self.haveReturnedResult == NO) {
            // block has not fired before stop was called, return whatever result we currently have
            [self returnSensorInfo];
        }
        [self.motionManager stopGyroUpdates];
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
