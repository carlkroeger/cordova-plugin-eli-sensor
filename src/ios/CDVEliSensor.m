
#import <CoreMotion/CoreMotion.h>
#import "CDVEliSensor.h"

@interface CDVEliSensor () {}
@property (readwrite, assign) BOOL isRunning;
@property (readwrite, assign) BOOL haveReturnedResult;
@property (readwrite, strong) CMMotionManager* motionManager;
@property (readwrite, assign) NSTimeInterval timestamp;
@end

@implementation CDVEliSensor

@synthesize callbackId, isRunning, timestamp;

// defaults to 10 msec
#define kUpdateInterval 10

- (CDVEliSensor*)init
{
    self = [super init];
    if (self) {
        //self.sensor_dict = @{ @"1" : @"TYPE_ACCELEROMETER", @"4" : @"TYPE_GYROSCOPE",@"15" : @"TYPE_GAME_ROTATION_VECTOR"};
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

  if([s_type intValue] == 1 && [self.motionManager isAccelerometerAvailable] == YES) {
    // Assign the update interval to the motion manager and start updates
    [self.motionManager setAccelerometerUpdateInterval:kUpdateInterval/1000];  // expected in seconds
    //__weak CDVEliSensor* weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
      NSArray* data_result = [[NSArray alloc] initWithObjects:
                                [NSNumber numberWithFloat:accelerometerData.acceleration.x],
                                [NSNumber numberWithFloat:accelerometerData.acceleration.y],
                                [NSNumber numberWithFloat:accelerometerData.acceleration.z],
                                , nil];
      NSNumber timestamp = ([[NSDate date] timeIntervalSince1970] * 1000);
      //[weakSelf returnSensorInfo];
      NSMutableDictionary* return_dict = [NSMutableDictionary dictionaryWithCapacity:2];
      [return_dict setValue:[data_result] forKey:@"data"];
      [return_dict setValue:[timestamp] forKey:@"timestamp"];
      // debería retornar: "{ data: array_resultados, timestamp: 12984378798 }""
      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:return_dict];
      [result setKeepCallback:[NSNumber numberWithBool:YES]];
      [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
      self.haveReturnedResult = YES;
    }];
    if (!self.isRunning) {
      self.isRunning = YES;
    }
  }else if([s_type intValue] == 4 && [self.motionManager isGyroAvailable] == YES) {
    // Assign the update interval to the motion manager and start updates
    [self.motionManager setGyroUpdateInterval:kUpdateInterval/1000];
    __weak CDVEliSensor* weakSelf = self;
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
      NSArray* data_result = [[NSArray alloc] initWithObjects:
                                [NSNumber numberWithFloat:gyroData.rotationRate.x],
                                [NSNumber numberWithFloat:gyroData.rotationRate.y],
                                [NSNumber numberWithFloat:gyroData.rotationRate.z],
      NSNumber timestamp = ([[NSDate date] timeIntervalSince1970] * 1000);
      //[weakSelf returnSensorInfo];
      NSMutableDictionary* return_dict = [NSMutableDictionary dictionaryWithCapacity:2];
      [return_dict setValue:[data_result] forKey:@"data"];
      [return_dict setValue:[timestamp] forKey:@"timestamp"];
      // debería retornar: "{ data: array_resultados, timestamp: 12984378798 }""
      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:return_dict];
      [result setKeepCallback:[NSNumber numberWithBool:YES]];
      [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
      self.haveReturnedResult = YES;
    }];
    if (!self.isRunning) {
      self.isRunning = YES;
    }
  }else if([s_type intValue] == 15 && [self.motionManager isDeviceMotionAvailable] == YES) {
    // Assign the update interval to the motion manager and start updates
    [self.motionManager setDeviceMotionUpdateInterval:kUpdateInterval/1000];
    //__weak CDVEliSensor* weakSelf = self;
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotionData *motionData, NSError *error) {      
      // Get the attitude of the device
      //CMAttitude *attitude = motion.attitude;
      // Get the pitch (in radians) and convert to degrees.                                          
      //NSLog(@"%f", attitude.pitch * 180.0/M_PI);
      NSArray* data_result = [[NSArray alloc] initWithObjects:
                                [NSNumber numberWithFloat:motionData.attitude.yaw * 180.0 / M_PI],
                                [NSNumber numberWithFloat:motionData.attitude.pitch * 180.0 / M_PI],
                                [NSNumber numberWithFloat:motionData.attitude.roll * 180.0 / M_PI],
      NSNumber timestamp = ([[NSDate date] timeIntervalSince1970] * 1000);
      //[weakSelf returnSensorInfo];
      NSMutableDictionary* return_dict = [NSMutableDictionary dictionaryWithCapacity:2];
      [return_dict setValue:[data_result] forKey:@"data"];
      [return_dict setValue:[timestamp] forKey:@"timestamp"];
      // debería retornar: "{ data: array_resultados, timestamp: 12984378798 }""
      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:return_dict];
      [result setKeepCallback:[NSNumber numberWithBool:YES]];
      [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
      self.haveReturnedResult = YES;
    }];
    if (!self.isRunning) {
      self.isRunning = YES;
    }
  }else{  
    NSLog(@"Running in Simulator? All sensor tests will fail.");
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Error. EliSensor Not Available."];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
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
    if ([self.motionManager isGyroActive] == YES) {
        [self.motionManager stopGyroUpdates];
    }
    if ([self.motionManager isAccelerometerActive] == YES) {
        [self.motionManager stopAccelerometerUpdates];
    }
    if ([self.motionManager isDeviceMotionActive] == YES) {
        [self.motionManager stopDeviceMotionUpdates];
    }
    self.isRunning = NO;
}

// - (void)returnSensorInfo
// {
//     // Create an orientation object
//     NSMutableDictionary* orientationProps = [NSMutableDictionary dictionaryWithCapacity:4];

//     [orientationProps setValue:[NSNumber numberWithDouble:x] forKey:@"x"];
//     [orientationProps setValue:[NSNumber numberWithDouble:y] forKey:@"y"];
//     [orientationProps setValue:[NSNumber numberWithDouble:z] forKey:@"z"];
//     [orientationProps setValue:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];

//     CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:orientationProps];
//     [result setKeepCallback:[NSNumber numberWithBool:YES]];
//     [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
//     self.haveReturnedResult = YES;
// }

@end
