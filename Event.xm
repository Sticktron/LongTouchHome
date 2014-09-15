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


#define LASendEventWithName(eventName) \
	[LASharedActivator sendEventToListener:[LAEvent eventWithName:eventName mode:[LASharedActivator currentEventMode]]]

static NSString *kLongTouchHome_eventName = @"LongTouchHomeEvent";

#define TouchIDFingerUp    0
#define TouchIDFingerDown  1
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDNotMatched  9



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



/*
//@interface LTHTouchIDController : NSObject <BiometricKitDelegate> {
//	BOOL _wasMatching;
//	id _monitorDelegate;
//	NSArray *_monitorObservers;
//	BOOL isMonitoringEvents;
//}
//@end
//
//@implementation LTHTouchIDController
//
//- (void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned long long)event {
//	DebugLog(@"event: %llu", event);
//	
//	switch (event) {
//		case TouchIDFingerDown:
//			DebugLog(@">>> finger touchdown!");
//			break;
//		case TouchIDFingerUp:
//			DebugLog(@">>> finger removed!");
//			break;
//		case TouchIDFingerHeld:
//			DebugLog(@">>> finger held");
//			break;
//	}
//}
//
//- (void)startMonitoringEvents {
//	if (isMonitoringEvents) {
//		return;
//	}
//	
//	isMonitoringEvents = YES;
//	
//	_monitorDelegate = [[%c(BiometricKit) manager] delegate];
//	
//	SBUIBiometricEventMonitor *bioMonitor = [%c(SBUIBiometricEventMonitor) sharedInstance];
//	
//	[[%c(BiometricKit) manager] setDelegate:bioMonitor];
//	
//	_wasMatching = [[bioMonitor valueForKey:@"_matchingEnabled"] boolValue];
//	_monitorObservers = [[bioMonitor valueForKey:@"observers"] copy];
//	
//	for (int i=0; i < _monitorObservers.count; i++) {
//		[bioMonitor removeObserver:[[bioMonitor valueForKey:@"observers"] objectAtIndex:i]];
//	}
//	
//	[bioMonitor addObserver:self];
//	[bioMonitor _setMatchingEnabled:YES];
//	[bioMonitor _startMatching];
//}
//
//- (void)stoptMonitoringEvents {
//    if (!isMonitoringEvents) {
//		return;
//	}
//	
////	id manager = [objc_getClass("BiometricKit") manager];
////	DebugLog(@"manager=%@", manager);
////	
////	id monitor = [manager delegate];
////	DebugLog(@"monitor=%@", monitor);
////	
////	[monitor removeObserver:self];
////	
////	for (id observer in _monitorObservers) {
////		 [monitor addObserver:observer];
////	}
////	[monitor _setMatchingEnabled:_wasMatching];
////
////	[[objc_getClass("BiometricKit") manager] removeObserver:self];
////	
//	isMonitoringEvents=NO;
//}
//
//@end
//
*/





////////////////////////////////////////////////////////////////
// Event Handler

//static void HandleEvent(CFNotificationCenterRef center,
//						void *observer,
//						CFStringRef name,
//						const void *object,
//						CFDictionaryRef userInfo) {
//	
//	DebugLogC(@"*** HandleEvent named: %@ with stuff: %@ ***", (NSString *)name, userInfo);
//	
//	LASendEventWithName(kLongTouchHome_eventName);
//	DebugLogC(@"*** LASent: %@ ***", kLongTouchHome_eventName);
//	
//}





////////////////////////////////////////////////////////////////
// Event Class

@interface LongTouchOnHomeDataSource : NSObject <LAEventDataSource> {}
+ (id)sharedInstance;
@end

//static LongTouchOnHomeDataSource *me;

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
	return @"Fingerprint Stuff";
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



////////////////////////////////////////////////////////////////
// Event Dispatch

%hook SBLockScreenManager

- (void)biometricEventMonitor:(SBUIBiometricEventMonitor *)arg1 handleBiometricEvent:(unsigned long long)event {
	DebugLog(@"*** biometric event: %llu", event);
	
	switch (event) {
		case TouchIDFingerHeld:
			DebugLog(@">>> finger held");
			
			LASendEventWithName(kLongTouchHome_eventName);
			
			DebugLog(@">>> event sent");
			break;
	}
	
	%orig;
}

%end





////////////////////////////////////////////////////////////////
// Init

%ctor {
	@autoreleasepool {
		NSLog(@"    LongTouchHome LAEvent init.   ");
		
//		LTHTouchIDController *controller = [[LTHTouchIDController alloc] init];
//		[controller startMonitoringEvents];
		
		%init;
		
//		CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
//		CFNotificationCenterAddObserver(center,
//										NULL,
//										HandleEvent,
//										(CFStringRef)kLongTouchHome_eventName,
//										NULL,
//										CFNotificationSuspensionBehaviorCoalesce);
	};
}
