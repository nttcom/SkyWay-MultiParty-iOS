//
//  AppDelegate.m
//  TestMultiParty
//

#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>


@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Override point for customization after application launch.
	
	// Audio session
	[self initAudioSession];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

	// Audio session
	[self termAudioSession];
}

#pragma mark - AVAudioSession

- (void)initAudioSession
{
	NSError* error = nil;
	AVAudioSession* avSession = [AVAudioSession sharedInstance];
	
	[avSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
	[avSession setMode:AVAudioSessionModeVideoChat error:&error];
	[avSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
	
	NSNotificationCenter* notif = [NSNotificationCenter defaultCenter];
	//	[notif addObserver:self selector:@selector(audioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
	[notif addObserver:self selector:@selector(audioSessionRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
	//	[notif addObserver:self selector:@selector(audioSessionSilence:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
	
	[avSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
}

- (void)termAudioSession
{
	NSError* error = nil;
	AVAudioSession* avSession = [AVAudioSession sharedInstance];
	
	[avSession setActive:NO error:&error];
	
	NSNotificationCenter* notif = [NSNotificationCenter defaultCenter];
	[notif removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
	[notif removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
	[notif removeObserver:self name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
}

- (void)audioSessionInterruption:(NSNotification *)notif
{
	NSDictionary* dicInfo = notif.userInfo;
	NSLog(@"%@", dicInfo);
	
	NSInteger iType = [dicInfo[AVAudioSessionInterruptionTypeKey] integerValue];
	if (AVAudioSessionInterruptionTypeBegan == iType)
	{
		NSLog(@"AVAudioSessionInterruptionTypeBegan");
	}
	else if (AVAudioSessionInterruptionTypeEnded == iType)
	{
		NSLog(@"AVAudioSessionInterruptionTypeEnded");
	}
}

- (void)audioSessionRouteChanged:(NSNotification *)notif
{
	NSDictionary* dicInfo = notif.userInfo;
	NSLog(@"%@", dicInfo);
	
	AVAudioSession* avSession = [AVAudioSession sharedInstance];
	
	AVAudioSessionRouteDescription* route = [avSession currentRoute];
	NSArray* aryOuts = [route outputs];
	
	AVAudioSessionPortDescription* desc = [aryOuts objectAtIndex:0];
	
	if (NSOrderedSame == [desc.portType caseInsensitiveCompare:AVAudioSessionPortBuiltInReceiver])
	{
		// Receiver
		[self performSelectorInBackground:@selector(setSpeaker) withObject:nil];
	}
	
	NSInteger iType = [dicInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
	if (AVAudioSessionRouteChangeReasonUnknown == iType)
	{
		// Unknwon
	}
	else if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == iType)
	{
		// New device
	}
	else if (AVAudioSessionRouteChangeReasonOldDeviceUnavailable == iType)
	{
		// Old device
	}
	else if (AVAudioSessionRouteChangeReasonCategoryChange == iType)
	{
		// Category change
	}
	else if (AVAudioSessionRouteChangeReasonOverride == iType)
	{
		// Override
	}
	else if (AVAudioSessionRouteChangeReasonWakeFromSleep == iType)
	{
		// Wake from sleep
	}
	else if (AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory == iType)
	{
		// No suitable route for category
	}
	else if (AVAudioSessionRouteChangeReasonRouteConfigurationChange == iType)
	{
		// Route configuration change
	}
}

- (void)audioSessionSilence:(NSNotification *)notif
{
	NSDictionary* dicInfo = notif.userInfo;
	NSLog(@"%@", dicInfo);
}

- (void)setSpeaker
{
	BOOL bResult = 0;
	NSError* error = nil;
	
	AVAudioSession* avSession = [AVAudioSession sharedInstance];
	
	bResult = [avSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
	if (NO == bResult)
	{
		NSLog(@"%@", error);
	}
}

@end
