//
//  Long Touch Home : Activator Event
//
//  Created by Sticktron, 2014.
//
//

#import <Foundation/Foundation.h>
#import <libactivator/libactivator.h>
#include <dispatch/dispatch.h>
#include <objc/runtime.h>

#define DEBUG_PREFIX @"{ LongTouchHome }"
#import "DebugLog.h"

#define TouchIDFingerUp    0
#define TouchIDFingerDown  1
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDNotMatched  9

#define LASendEventWithName(eventName) \
	[LASharedActivator sendEventToListener:[LAEvent eventWithName:eventName mode:[LASharedActivator currentEventMode]]]

static NSString *kLongTouchHome_eventName = @"LongTouchHomeEvent";



// Interfaces
@protocol BiometricKitDelegate <NSObject>
@optional
- (void)homeButtonPressed;
- (void)enrollProgress:(id)arg1;
- (void)statusMessage:(unsigned int)arg1;
- (void)matchResult:(id)arg1 withDetails:(id)arg2;
- (void)matchResult:(id)arg1;
- (void)enrollResult:(id)arg1;
@end

@interface BiometricKit : NSObject <BiometricKitDelegate>
+ (id)manager;
@end

@interface SBUIBiometricEventMonitor : NSObject <BiometricKitDelegate>
- (void)addObserver:(id)arg1;
- (void)removeObserver:(id)arg1;
@end



// My Activator Event Class

@interface LongTouchOnHomeDataSource : NSObject <LAEventDataSource> {}
+ (id)sharedInstance;
@end

@implementation LongTouchOnHomeDataSource
+ (id)sharedInstance {
	DebugLog(@"*** LongTouch::sharedInstance");
	
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}
+ (void)load {
	[self sharedInstance];
}
- (id)init {
	if ((self = [super init])) {
		// Register our event
		[LASharedActivator registerEventDataSource:self forEventName:kLongTouchHome_eventName];
	}
	return self;
}
- (NSString *)localizedTitleForEventName:(NSString *)eventName {
	return @"Long touch on Home";
}
- (NSString *)localizedGroupForEventName:(NSString *)eventName {
	return @"Fingerprint Sensor";
}
- (NSString *)localizedDescriptionForEventName:(NSString *)eventName {
	return @"Long touch on the fingerprint sensor.";
}
- (void)biometricEventMonitor:(SBUIBiometricEventMonitor *)arg1 handleBiometricEvent:(unsigned long long)arg2 {
	DebugLog(@"*** biometric event: %llu", arg2);
}
- (void)dealloc {
	[LASharedActivator unregisterEventDataSourceWithEventName:kLongTouchHome_eventName];
	[super dealloc];
}
@end



// Event Dispatcher
%hook SBLockScreenManager
- (void)biometricEventMonitor:(SBUIBiometricEventMonitor *)arg1 handleBiometricEvent:(unsigned long long)event {
	DebugLog(@"biometric event: %llu", event);
	
	if (event == TouchIDFingerHeld) {
		LASendEventWithName(kLongTouchHome_eventName);
		DebugLog(@">>> event sent to Activator...");
	}
	%orig;
}
%end



// Init
%ctor {
	@autoreleasepool {
		NSLog(@"    LongTouchHome LAEvent init.   ");
		%init;
	};
}

