
#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

@interface CDVEliSensor : CDVPlugin
{
    NSTimeInterval timestamp;
}

@property (readonly, assign) BOOL isRunning;
@property (nonatomic, strong) NSString* callbackId;

- (CDVEliSensor*)init;

- (void)start:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;
- (void)sensor_list:(CDVInvokedUrlCommand*)command;

@end
