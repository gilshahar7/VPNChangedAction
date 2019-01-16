#import <libactivator/libactivator.h>

#define LASendEventWithName(eventName) [LASharedActivator sendEventToListener:[LAEvent eventWithName:eventName mode:[LASharedActivator currentEventMode]]]
static NSString *kVPNChanged_eventName = @"VPNChanged";
static NSString *kVPNConnected_eventName = @"VPNConnected";
static NSString *kVPNDisconnected_eventName = @"VPNDisconnected";

@interface SBTelephonyManager : NSObject
+ (instancetype)sharedTelephonyManager;
-(bool)isUsingVPNConnection;
@end


/////////////ACTIVATOR CODE


@interface VPNChangedDataSource : NSObject <LAEventDataSource> {}
+ (id)sharedInstance;
@end

@implementation VPNChangedDataSource
+ (id)sharedInstance {
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
		[LASharedActivator registerEventDataSource:self forEventName:kVPNChanged_eventName];
		[LASharedActivator registerEventDataSource:self forEventName:kVPNConnected_eventName];
		[LASharedActivator registerEventDataSource:self forEventName:kVPNDisconnected_eventName];
	}
	return self;
}

- (NSString *)localizedTitleForEventName:(NSString *)eventName {
	if([eventName isEqualToString:kVPNChanged_eventName]){
		return @"VPN Status Changed";
	}else if([eventName isEqualToString:kVPNConnected_eventName]){
		return @"VPN Connected";
	}else{
		return @"VPN Disconnected";
	}

}

- (NSString *)localizedGroupForEventName:(NSString *)eventName {
	return @"Network Status";
}

- (NSString *)localizedDescriptionForEventName:(NSString *)eventName {
	if([eventName isEqualToString:kVPNChanged_eventName]){
		return @"Triggers when the VPN connection is changed";
	}else if([eventName isEqualToString:kVPNConnected_eventName]){
		return @"Triggers when the VPN has connected";
	}else{
		return @"Triggers when the VPN has disconnected";
	}
}

- (void)dealloc {
	[LASharedActivator unregisterEventDataSourceWithEventName:kVPNChanged_eventName];
	[LASharedActivator unregisterEventDataSourceWithEventName:kVPNConnected_eventName];
	[LASharedActivator unregisterEventDataSourceWithEventName:kVPNDisconnected_eventName];
	[super dealloc];
}
@end


/////////////MY CODE


static bool savedstatus;

%hook SBTelephonyManager
-(SBTelephonyManager *)init{
	SBTelephonyManager *origself = %orig;
	bool tempstatus = [origself isUsingVPNConnection];
	savedstatus = tempstatus;
	return origself;
}
%end


%hook SBStatusBarStateAggregator
-(void)_updateVPNItem
{
	%orig;
	SBTelephonyManager *telephonyManager = (SBTelephonyManager *)[%c(SBTelephonyManager) sharedTelephonyManager];
	bool currentstatus = [telephonyManager isUsingVPNConnection];
    if (currentstatus != savedstatus)
    {
		LASendEventWithName(kVPNChanged_eventName);
		if(currentstatus == true){
			LASendEventWithName(kVPNConnected_eventName);
		}else{
			LASendEventWithName(kVPNDisconnected_eventName);
		}
		savedstatus = currentstatus;
	}
}
%end




%ctor {
	@autoreleasepool {
		%init;
	};
}