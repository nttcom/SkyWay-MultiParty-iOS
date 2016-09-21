//
//  MultiPartyViewController.m
//  TestMultiParty
//

#import "MultiPartyViewController.h"

#import <MultiParty.h>
#import <SkyWay/SKWVideo.h>


typedef NS_ENUM(NSUInteger, ViewTag)
{
	TAG_ID = 1100,
	TAG_WEBRTC_ACTION,
	TAG_REMOTE_VIDEO,
	TAG_LOCAL_VIDEO,
	TAG_MESSAGE,
	TAG_PREV_STREAM,
	TAG_NEXT_STREAM,
	TAG_TOGGLE_VIDEO,
	TAG_TOGGLE_AUDIO,
	TAG_CLOSE,
	TAG_TERM,
	TAG_RECONNECT,
	TAG_SEND_MSG,
};

#define BUTTON_WIDTH		(72.0f)
#define BUTTON_HEIGHT		(48.0f)

@interface MultiPartyViewController () < UINavigationControllerDelegate >
{
	MultiParty*			_mp;
	SKWMediaStream*		_msLocal;
	
	NSString*			_strRoomName;
	
	NSMutableArray*		_maryRemoteStream;
	SKWMediaStream*		_msCurrent;
	
	NSDateFormatter*	_fmtDate;
}
@end


@implementation MultiPartyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	_mp = nil;
	_msLocal = nil;
	_maryRemoteStream = [[NSMutableArray alloc] init];
	
	_fmtDate = [[NSDateFormatter alloc] init];
	[_fmtDate setDateFormat:@"HH:mm:ss"];
	
	[self.navigationController setDelegate:self];
	
	[self.view setBackgroundColor:[UIColor whiteColor]];
	
	// Gesture
	UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
	
	// Initialize views
	//
	CGRect rcScreen = self.view.bounds;
	if (NSFoundationVersionNumber_iOS_6_1 < NSFoundationVersionNumber)
	{
		CGFloat fValue = [UIApplication sharedApplication].statusBarFrame.size.height;
		rcScreen.origin.y = fValue;
		if (nil != self.navigationController)
		{
			if (NO == self.navigationController.navigationBarHidden)
			{
				fValue = self.navigationController.navigationBar.frame.size.height;
				rcScreen.origin.y += fValue;
			}
		}
	}
	
	// Remote video
	{
		CGRect rcRemote = CGRectZero;
		if (UIUserInterfaceIdiomPad == [UIDevice currentDevice].userInterfaceIdiom)
		{
			// iPad
			rcRemote.size.width = 480.0f;
			rcRemote.size.height = 480.0f;
		}
		else
		{
			// iPhone / iPod touch
			rcRemote.size.width = rcScreen.size.width;
			rcRemote.size.height = rcRemote.size.width;
		}
		rcRemote.origin.x = (rcScreen.size.width - rcRemote.size.width) / 2.0f;
		rcRemote.origin.y = (rcScreen.size.height - rcRemote.size.height) / 2.0f;
		rcRemote.origin.y -= 8.0f;
		
		SKWVideo* video = [[SKWVideo alloc] initWithFrame:rcRemote];
		[video setTag:TAG_REMOTE_VIDEO];
		[video setUserInteractionEnabled:NO];
		[video addGestureRecognizer:tapGesture];
		[self.view addSubview:video];
	}
	
	// Local video
	{
		CGRect rcLocal = CGRectZero;
		if (UIUserInterfaceIdiomPad == [UIDevice currentDevice].userInterfaceIdiom)
		{
			rcLocal.size.width = rcScreen.size.width / 5.0f;
			rcLocal.size.height = rcScreen.size.height / 5.0f;
		}
		else
		{
			rcLocal.size.width = rcScreen.size.height / 5.0f;
			rcLocal.size.height = rcLocal.size.width;
		}
		rcLocal.origin.x = rcScreen.size.width - rcLocal.size.width - 8.0f;
		rcLocal.origin.y = rcScreen.size.height - rcLocal.size.height - 8.0f;
		
		SKWVideo* video = [[SKWVideo alloc] initWithFrame:rcLocal];
		[video setTag:TAG_LOCAL_VIDEO];
		[video addGestureRecognizer:tapGesture];
		[self.view addSubview:video];
	}
	
	// Message
	{
		CGRect rc = CGRectZero;
		rc.size.width = (rcScreen.size.width / 2.0f);
		rc.size.height = (rcScreen.size.height / 4.0f);
		rc.origin.x = 0.0f;
		rc.origin.y = (rcScreen.size.height - rc.size.height);
		
		UIFont* fnt = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		
		UITextView* tv = [[UITextView alloc] initWithFrame:rc];
		[tv setTag:TAG_MESSAGE];
		[tv setTextColor:[UIColor blackColor]];
		[tv setFont:fnt];
		[tv setBackgroundColor:nil];
		[tv setEditable:NO];
		[tv setSelectable:YES];
		[tv setText:@""];
		[tv setOpaque:NO];
		
		[self.view addSubview:tv];
	}
	
	// Previous stream button
	{
		CGRect rc = CGRectZero;
		rc.size.width = 48.0f;
		rc.size.height = 48.0f;
		
		rc.origin.x = 0.0f;
		rc.origin.y = (rcScreen.size.height - rc.size.height) / 2.0f;
		
		NSString* strTitle = NSLocalizedString(@" < ", @"Previous stream");
		
		UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
		[button setTag:TAG_PREV_STREAM];
		[button setFrame:rc];
		[button setBackgroundColor:[UIColor lightGrayColor]];
		[button setTitle:strTitle forState:UIControlStateNormal];
		[button.layer setCornerRadius:4.0f];
		[button addTarget:self action:@selector(onTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.view addSubview:button];
	}
	
	// Next stream button
	{
		CGRect rc = CGRectZero;
		rc.size.width = 48.0f;
		rc.size.height = 48.0f;
		
		rc.origin.x = rcScreen.size.width - rc.size.width;
		rc.origin.y = (rcScreen.size.height - rc.size.height) / 2.0f;
		
		NSString* strTitle = NSLocalizedString(@" > ", @"Next stream");
		
		UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
		[button setTag:TAG_NEXT_STREAM];
		[button setFrame:rc];
		[button setBackgroundColor:[UIColor lightGrayColor]];
		[button setTitle:strTitle forState:UIControlStateNormal];
		[button.layer setCornerRadius:4.0f];
		[button addTarget:self action:@selector(onTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.view addSubview:button];
	}
	
	// Toggle local video
	{
		CGRect rc = CGRectZero;
		
		rc.size.width = BUTTON_WIDTH;
		rc.size.height = BUTTON_HEIGHT;
		
		rc.origin.x = rcScreen.origin.x;
		rc.origin.y = rcScreen.origin.y;
		
		NSString* strTitle = NSLocalizedString(@"Video", @"Disable local video button");
		
		UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
		[button setTag:TAG_TOGGLE_VIDEO];
		[button setFrame:rc];
		[button setBackgroundColor:[UIColor lightGrayColor]];
		[button setTitle:strTitle forState:UIControlStateNormal];
		[button setSelected:YES];
		[button.layer setCornerRadius:4.0f];
		[button addTarget:self action:@selector(onTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.view addSubview:button];
	}
	
	// Toggle local audio
	{
		CGRect rc = CGRectZero;
		
		rc.size.width = BUTTON_WIDTH;
		rc.size.height = BUTTON_HEIGHT;
		
		rc.origin.x = rcScreen.origin.x;
		rc.origin.y = rcScreen.origin.y + (rc.size.height);
		
		NSString* strTitle = NSLocalizedString(@"Audio", @"Disable local audio button");
		
		UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
		[button setTag:TAG_TOGGLE_AUDIO];
		[button setFrame:rc];
		[button setBackgroundColor:[UIColor lightGrayColor]];
		[button setTitle:strTitle forState:UIControlStateNormal];
		[button setSelected:YES];
		[button.layer setCornerRadius:4.0f];
		[button addTarget:self action:@selector(onTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.view addSubview:button];
	}
		
	// Send message button
	{
		CGRect rc = CGRectZero;
		
		rc.size.width = BUTTON_WIDTH;
		rc.size.height = BUTTON_HEIGHT;
		
		rc.origin.x = rcScreen.size.width - rc.size.width;
		rc.origin.y = rcScreen.size.height - rc.size.height;
		
		NSString* strTitle = NSLocalizedString(@"Send", @"Send message button");
		
		UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
		[button setTag:TAG_SEND_MSG];
		[button setFrame:rc];
		[button setBackgroundColor:[UIColor lightGrayColor]];
		[button setTitle:strTitle forState:UIControlStateNormal];
		[button.layer setCornerRadius:4.0f];
		[button addTarget:self action:@selector(onTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.view addSubview:button];
	}
	
	// Initialize MultiParty
	[self initMultiParty];
	
	[self queueUpdateUI];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	// 終了時には subview は全部削除.
	if (0 == [self.view.subviews count])
	{
		[self termMultiParty];
	}
	
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MultiParty

- (void)initMultiParty
{
	if (nil != _mp)
	{
		return;
	}
	
	MultiPartyOption* option = [[MultiPartyOption alloc] init];

    [option setKey:@"APIkey"];	// NTTCom/SkyWay Key
    [option setDomain:@"domain"];
    
	
//	[option setDebug:MP_DEBUG_LEVEL_ALL_LOGS];
	[option setRoom:_strRoomName];

	// MultiParty
	_mp = [[MultiParty alloc] initWithOption:option];

	[self setMultiPartyEvents:_mp];

	[_mp start];
}

- (void)termMultiParty
{
	for (SKWMediaStream* stream in _maryRemoteStream)
	{
		[stream close];
	}
	[_maryRemoteStream removeAllObjects];
	
	if (nil != _msCurrent)
	{
		[_msCurrent close];
	}
	_msCurrent = nil;
	
	if (nil != _msLocal)
	{
		[_msLocal close];
	}
	_msLocal = nil;
	
	if (nil != _mp)
	{
		[_mp close];
		_mp = nil;
	}
}


- (void)setMultiPartyEvents:(MultiParty *)mp
{
	[_mp on:MULTIPARTY_EVENT_OPEN callback:^(NSDictionary* dic) {
		NSLog(@"[MP/OPEN]%@", dic);
		
		NSObject* obj = dic[@"id"];
		if (nil != obj)
		{
			if ([obj isKindOfClass:[NSString class]])
			{
				NSString* strValue = (NSString *)obj;
				
				[self addMessage:strValue];
			}
		}
	}];
	
	[_mp on:MULTIPARTY_EVENT_MY_MS callback:^(NSDictionary* dic) {
		NSLog(@"[MP/MY_MS]%@", dic);
		
		SKWMediaStream* stream = nil;
		
		NSObject* obj = dic[@"src"];
		if (nil != obj)
		{
			if ([obj isKindOfClass:[SKWMediaStream class]])
			{
				stream = (SKWMediaStream *)obj;
			}
		}

		[self setLocalVideoSource:stream];
	}];
	
	[_mp on:MULTIPARTY_EVENT_PEER_MS callback:^(NSDictionary* dic) {
		NSLog(@"[MP/PEER_MS]%@", dic);
		
		SKWMediaStream* stream = nil;
		
		NSObject* obj = dic[@"src"];
		if (nil != obj)
		{
			if ([obj isKindOfClass:[SKWMediaStream class]])
			{
				stream = (SKWMediaStream *)obj;
			}
		}
		
		if (nil != stream)
		{
			if (0 == [_maryRemoteStream count])
			{
				[self setRemoteVideoSource:stream];
				
				_msCurrent = stream;
			}
			else
			{
				[stream setEnableVideoTrack:0 enable:NO];
			}
			
			[_maryRemoteStream addObject:stream];
		}
		
		[self queueUpdateUI];
	}];
	
	[_mp on:MULTIPARTY_EVENT_MS_CLOSE callback:^(NSDictionary* dic) {
		NSLog(@"[MP/MS_CLOSE]%@", dic);
		
		SKWMediaStream* stream = nil;
		
		NSObject* obj = dic[@"src"];
		if (nil != obj)
		{
			if ([obj isKindOfClass:[SKWMediaStream class]])
			{
				stream = (SKWMediaStream *)obj;
			}
		}
		
		if (nil != stream)
		{
            NSLog(@"[stream]%@", _maryRemoteStream);
			[_maryRemoteStream removeObject:stream];
			
			if (_msCurrent == stream)
			{
				[self unsetRemoteVideoSource:stream];
				
				_msCurrent = nil;
                
                NSUInteger num = [_maryRemoteStream count];
                
                NSLog(@"%lu", (unsigned long)num);
				
				if (0 < [_maryRemoteStream count])
				{
					_msCurrent = [_maryRemoteStream objectAtIndex:0];
					
					[_msCurrent setEnableVideoTrack:0 enable:YES];
					[self setRemoteVideoSource:_msCurrent];
				}
			}
		}
		
		[self queueUpdateUI];
	}];
	
	[_mp on:MULTIPARTY_EVENT_PEER_SS callback:^(NSDictionary* dic) {
		NSLog(@"[MP/PEER_SS]%@", dic);
		
		// TODO: Showing screen share media stream
		
		[self queueUpdateUI];
	}];
	
	[_mp on:MULTIPARTY_EVENT_SS_CLOSE callback:^(NSDictionary* dic) {
		NSLog(@"[MP/SS_CLOSE]%@", dic);
		
		// TODO: Hiding screen share media stream
		
		[self queueUpdateUI];
	}];
	
	[_mp on:MULTIPARTY_EVENT_DC_OPEN callback:^(NSDictionary* dic) {
		NSLog(@"[MP/DC_OPEN]%@", dic);
	}];
	
	[_mp on:MULTIPARTY_EVENT_MESSAGE callback:^(NSDictionary* dic) {
		NSLog(@"[MP/MESSAGE]%@", dic);
		
		NSObject* obj = dic[@"data"];
		if (nil != obj)
		{
			if ([obj isKindOfClass:[NSString class]])
			{
				NSString* strValue = (NSString *)obj;
				[self addMessage:strValue];
			}
		}
	}];
	
	[_mp on:MULTIPARTY_EVENT_DC_CLOSE callback:^(NSDictionary* dic) {
		NSLog(@"[MP/DC_CLOSE]%@", dic);
	}];
	
	[_mp on:MULTIPARTY_EVENT_ERROR callback:^(NSDictionary* dic) {
		NSLog(@"[MP/ERROR]%@", dic);
	}];
}

#pragma mark - Public

- (void)setRoomName:(NSString *)name
{
	_strRoomName = name;
}

#pragma mark - Private

- (void)updateUI
{
	BOOL bHidden = YES;
	
	if ((nil != _maryRemoteStream) && (1 < [_maryRemoteStream count]))
	{
		//
		bHidden = NO;
	}
	
	{
		UIButton* button = [self.view viewWithTag:TAG_PREV_STREAM];
		if (nil != button)
		{
			[button setHidden:bHidden];
		}
	}
	
	{
		UIButton* button = [self.view viewWithTag:TAG_NEXT_STREAM];
		if (nil != button)
		{
			[button setHidden:bHidden];
		}
	}
}

- (void)queueUpdateUI
{
	dispatch_queue_t queue = dispatch_get_main_queue();
	dispatch_async(queue, ^{
		[self updateUI];
	});
}

- (void)changeLocalStreamState
{
	BOOL bVideo = YES;
	BOOL bAudio = YES;
	
	{
		UIButton* button = [self.view viewWithTag:TAG_TOGGLE_VIDEO];
		if (nil != button)
		{
			bVideo = button.selected;
		}
	}
	
	if (NO == bVideo)
	{
		bVideo = YES;
	}
	else
	{
		bVideo = NO;
	}
	
	{
		UIButton* button = [self.view viewWithTag:TAG_TOGGLE_AUDIO];
		if (nil != button)
		{
			bAudio = button.selected;
		}
	}
	
	if (NO == bAudio)
	{
		bAudio = YES;
	}
	else
	{
		bAudio = NO;
	}
	
	[_mp muteVideo:bVideo audio:bAudio];
}

- (void)prevStream
{
	[self unsetRemoteVideoSource:_msCurrent];
	[_msCurrent setEnableVideoTrack:0 enable:NO];
	
	NSInteger iIndex = [_maryRemoteStream indexOfObject:_msCurrent];
	
	iIndex--;
	
	if (0 > iIndex)
	{
		iIndex = [_maryRemoteStream count];
		iIndex--;
	}
	
	_msCurrent = [_maryRemoteStream objectAtIndex:iIndex];
	
	[_msCurrent setEnableVideoTrack:0 enable:YES];
	[self setRemoteVideoSource:_msCurrent];
}

- (void)nextStream
{
	[self unsetRemoteVideoSource:_msCurrent];
	[_msCurrent setEnableVideoTrack:0 enable:NO];
	
	NSInteger iIndex = [_maryRemoteStream indexOfObject:_msCurrent];

	iIndex++;
	
	if (iIndex >= [_maryRemoteStream count])
	{
		iIndex = 0;
	}
	
	_msCurrent = [_maryRemoteStream objectAtIndex:iIndex];
	
	[_msCurrent setEnableVideoTrack:0 enable:YES];
	[self setRemoteVideoSource:_msCurrent];
}

- (void)addMessage:(NSString *)message
{
	UITextView* tv =(UITextView *)[self.view viewWithTag:TAG_MESSAGE];
	if (nil == tv)
	{
		return;
	}
	
	NSDate* date = [NSDate date];
	NSString* strDate = [_fmtDate stringFromDate:date];
	
	NSMutableString* mstr = [[NSMutableString alloc] init];
	[mstr appendString:@"["];
	[mstr appendString:strDate];
	[mstr appendString:@"]"];
	[mstr appendString:message];
	[mstr appendString:@"\n"];

	dispatch_queue_t queue = dispatch_get_main_queue();
	dispatch_async(queue, ^{
		tv.text = [tv.text stringByAppendingString:mstr];
	});
}

- (void)sendMessage
{
	UIDevice* device = [UIDevice currentDevice];
	
	NSString* strModel = [device model];
	NSString* strName = [device name];
	NSString* strMsg = [NSString stringWithFormat:@"[%@/%@]Hello", strModel, strName];
	
	[_mp send:strMsg];
	
	[self addMessage:strMsg];
}

#pragma mark - Utility

- (BOOL)setLocalVideoSource:(SKWMediaStream *)stream
{
	_msLocal = stream;
	
	SKWVideo* video = (SKWVideo *)[self.view viewWithTag:TAG_LOCAL_VIDEO];
	if (nil == video)
	{
		return NO;
	}
	
	return [video addSrc:stream track:0];
}

- (BOOL)unsetLocalVideoSource
{
	if (nil == _msLocal)
	{
		return NO;
	}
	
	SKWVideo* video = (SKWVideo *)[self.view viewWithTag:TAG_LOCAL_VIDEO];
	if (nil == video)
	{
		return NO;
	}
	
	return [video removeSrc:_msLocal track:0];
}

- (BOOL)setRemoteVideoSource:(SKWMediaStream *)stream
{
	SKWVideo* video = (SKWVideo *)[self.view viewWithTag:TAG_REMOTE_VIDEO];
	if (nil == video)
	{
		return NO;
	}
	
	return [video addSrc:stream track:0];
}

- (BOOL)unsetRemoteVideoSource:(SKWMediaStream *)stream
{
	SKWVideo* video = (SKWVideo *)[self.view viewWithTag:TAG_REMOTE_VIDEO];
	if (nil == video)
	{
		return NO;
	}
	
	return [video removeSrc:stream track:0];
}

- (void)detachedRemoteStream
{
    SKWVideo* video = (SKWVideo *)[self.view viewWithTag:TAG_REMOTE_VIDEO];
    if (nil == video)
    {
        return;
    }
    
    for (SKWMediaStream* stream in _maryRemoteStream)
    {
        [video removeSrc:stream track:0];
    }
}

- (void)removeSubviews:(UIView *)vw
{
    while (0 < [vw.subviews count])
    {
        UIView* vwSub = [vw.subviews objectAtIndex:0];
        if (0 < [vwSub.subviews count])
        {
            [self removeSubviews:vwSub];
        }
        
        [vwSub removeFromSuperview];
    }
}

#pragma mark - Delegate

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    if (nil == parent)
    {
        // Back
        [self detachedRemoteStream];
        
        [self unsetLocalVideoSource];
        
        [self removeSubviews:self.view];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (nil == parent)
    {
        [self.navigationController setDelegate:nil];
    }
}

- (void)onTap:(UITapGestureRecognizer *)tap
{
	if (nil == tap)
	{
		return;
	}
	
	if ([tap.view isKindOfClass:[SKWVideo class]])
	{
		SKWVideo* video = (SKWVideo *)tap.view;
		
		if (TAG_LOCAL_VIDEO == [video tag])
		{
			if (nil != _msLocal)
			{
				SKWCameraPositionEnum pos = [_msLocal getCameraPosition];
				if (SKW_CAMERA_POSITION_FRONT == pos)
				{
					pos = SKW_CAMERA_POSITION_BACK;
				}
				else if (SKW_CAMERA_POSITION_BACK == pos)
				{
					pos = SKW_CAMERA_POSITION_FRONT;
				}
				
				[_msLocal setCameraPosition:pos];
			}
		}
	}
}

- (void)onTouchUpInside:(NSObject *)sender
{
	if (nil == sender)
	{
		return;
	}
	
	if ([sender isKindOfClass:[UIButton class]])
	{
		UIButton* button = (UIButton *)sender;
		
		NSInteger tag = [button tag];
		
		if (TAG_PREV_STREAM == tag)
		{
			// Prev stream
			[self prevStream];
		}
		else if (TAG_NEXT_STREAM == tag)
		{
			// Next stream
			[self nextStream];
		}
		else if (TAG_SEND_MSG == tag)
		{
			// Send message
			[self sendMessage];
		}
		else if ((TAG_TOGGLE_VIDEO == tag) || (TAG_TOGGLE_AUDIO == tag))
		{
			// Change local stream status
			if (NO == button.selected)
			{
				[button setSelected:YES];
			}
			else
			{
				[button setSelected:NO];
			}
			
			[self changeLocalStreamState];
		}
	}
}

@end
