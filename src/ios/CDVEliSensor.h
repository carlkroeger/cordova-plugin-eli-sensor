
#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

@interface CDVEliSensor : CDVPlugin
{
    double x;
    double y;
    double z;
    int sensor_type;
    NSDictionary *sensor_dict;
    NSDictionary *sensor_data;
    NSDictionary *data;
    NSTimeInterval timestamp;
}

@property (readonly, assign) BOOL isRunning;
@property (nonatomic, strong) NSString* callbackId;

- (CDVEliSensor*)init;

- (void)start:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;

@end
