
#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

@interface CDVEliSensor : CDVPlugin
{
    double x;
    double y;
    double z;
    int sensor_type;
    __unsafe_unretained NSDictionary *sensor_dict;
    __unsafe_unretained NSMutableDictionary *sensor_list;
    __unsafe_unretained NSMutableArray *sensor_list2;
    __unsafe_unretained NSArray *data;
    NSTimeInterval timestamp;
}

@property (readonly, assign) BOOL isRunning;
@property (nonatomic, strong) NSString* callbackId;

- (CDVEliSensor*)init;

- (void)start:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;
- (void)sensor_list:(CDVInvokedUrlCommand*)command;

@end
