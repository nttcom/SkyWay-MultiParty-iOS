//
//  ViewController.m
//  TestMultiParty
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

#import <MultiParty.h>

#import "MultiPartyViewController.h"


typedef NS_ENUM(NSUInteger, ViewTag)
{
	TAG_ID = 1000,
	TAG_ROOMNAME,
	TAG_SIGNIN,
};


@interface ViewController () < UITextFieldDelegate >
{
}
@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	CGRect rcClient = CGRectInset([self.view bounds], 4.0f, 8.0f);
	CGFloat fHeight = rcClient.size.height / 7.0f;
	
	// Base
	UIScrollView* base = [[UIScrollView alloc] initWithFrame:[self.view bounds]];
	[base setContentSize:CGSizeMake(self.view.bounds.size.width, (self.view.bounds.size.height))];
	
	[self.view addSubview:base];
	
	// Room name
	{
		CGRect rc = CGRectZero;
		rc.size.width = rcClient.size.width;
		rc.size.height = fHeight;
		rc.origin.y = (fHeight * 2.0f);
		
		rc = CGRectInset(rc, 0.0f, 2.0f);
		
		NSString* strPlaceHolder = NSLocalizedString(@"Room name", @"Room name text field");
		
		UITextField* tf = [[UITextField alloc] initWithFrame:rc];
		[tf setTag:TAG_ROOMNAME];
		[tf setPlaceholder:strPlaceHolder];
		[tf setTextColor:[UIColor blackColor]];
		[tf setTextAlignment:NSTextAlignmentCenter];
		[tf setKeyboardType:UIKeyboardTypeASCIICapable];
		[tf setClearButtonMode:UITextFieldViewModeAlways];
		[tf setReturnKeyType:UIReturnKeyDone];
		[tf setDelegate:self];
		[tf setBackgroundColor:[UIColor colorWithWhite:0.95f alpha:1.0f]];
		
		[base addSubview:tf];
	}
	
	// Sign in
	{
		CGRect rc = CGRectZero;
		rc.size.width = rcClient.size.width;
		rc.size.height = fHeight;
		rc.origin.y = (fHeight * 4.0f);

		rc = CGRectInset(rc, 0.0f, 2.0f);
		
		NSString* strTitle = NSLocalizedString(@"Sign in", @"sign in button");
		
		UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
		[button setTag:TAG_SIGNIN];
		[button setFrame:rc];
		[button setBackgroundColor:[UIColor colorWithWhite:0.8f alpha:1.0f]];
		[button setTitle:strTitle forState:UIControlStateNormal];
		[button addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		[button.layer setCornerRadius:4.0f];
		
		[base addSubview:button];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self checkVideoDeviceAuthorization];
	[self checkAudioDeivceAuthorization];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Peripheral authorization

- (void)checkVideoDeviceAuthorization
{
	// Camera
	AVAuthorizationStatus status =[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
	if (AVAuthorizationStatusAuthorized == status)
	{
		// Authorized
		
	}
	else if (AVAuthorizationStatusDenied == status)
	{
		// Denied
		NSString* strMsg = NSLocalizedString(@"The use of the camera is not allowed.", @"Message of denied access to camera.");
		[self showErrorWithTitle:@"" message:strMsg];
	}
	else if (AVAuthorizationStatusRestricted == status)
	{
		// Restricted
	}
	else if (AVAuthorizationStatusNotDetermined == status)
	{
		// Determinated
		[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
			// TODO: Code
			if (NO == granted)
			{
				// Denied
				NSString* strMsg = NSLocalizedString(@"The use of the camera is not allowed.", @"Message of denied access to camera.");
				[self showErrorWithTitle:@"" message:strMsg];
			}
			else
			{
				// Authorized
			}
		}];
	}
}

- (void)checkAudioDeivceAuthorization
{
	// Mic
	AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
	
	if (AVAuthorizationStatusAuthorized == status)
	{
		// Authorized
	}
	else if (AVAuthorizationStatusDenied == status)
	{
		// Denied
		NSString* strMsg = NSLocalizedString(@"The use of the mic is not allowed.", @"Message of denied access to mic.");
		[self showErrorWithTitle:@"" message:strMsg];
	}
	else if (AVAuthorizationStatusRestricted == status)
	{
		// Restricted
	}
	else if (AVAuthorizationStatusNotDetermined == status)
	{
		// Determinated
		[AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
			if (NO == granted)
			{
				// Denied
				NSString* strMsg = NSLocalizedString(@"The use of the mic is not allowed.", @"Message of denied access to mic.");
				[self showErrorWithTitle:@"" message:strMsg];
			}
			else
			{
				// Authorized
			}
		}];
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	
	return YES;
}

#pragma mark - UIAlertView / UIAlertController

- (void)showErrorWithTitle:(NSString *)strTitle message:(NSString *)strMessage
{
	if (nil == strTitle)
	{
		return;
	}
	
	NSString* strDone = NSLocalizedString(@"Done", @"Done button");
	
	if (NSFoundationVersionNumber_iOS_7_1 < NSFoundationVersionNumber)
	{
		// 8.0 later
		UIAlertController* ac = [UIAlertController alertControllerWithTitle:strTitle message:strMessage preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* aaDone = [UIAlertAction actionWithTitle:strDone style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
								 {
									 
								 }];
		[ac addAction:aaDone];
		
		dispatch_async(dispatch_get_main_queue(), ^
					   {
						   [self presentViewController:ac animated:YES completion:^
							{
								
							}];
					   });
	}
	else
	{
		// 7.1 earlier
		UIAlertView* av = [[UIAlertView alloc] initWithTitle:strTitle message:strMessage delegate:self cancelButtonTitle:strDone otherButtonTitles:nil];
		
		dispatch_async(dispatch_get_main_queue(), ^
					   {
						   [av show];
					   });
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
}

#pragma mark - Acton

- (void)touchUpInside:(NSObject *)sender
{
	if (YES == [sender isKindOfClass:[UIButton class]])
	{
		UIButton* button = (UIButton *)sender;
		
		if (TAG_SIGNIN == [button tag])
		{
			dispatch_queue_t queue = dispatch_get_main_queue();
			dispatch_async(queue, ^{
				NSString* strRoomName = nil;
				{
					UITextField* tf = (UITextField *)[self.view viewWithTag:TAG_ROOMNAME];
					if (nil != tf)
					{
						strRoomName = [tf text];
					}
				}
				
				MultiPartyViewController* vc = [[MultiPartyViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
				if (nil != vc)
				{
					[vc setRoomName:strRoomName];
					
					[self.navigationController pushViewController:vc animated:YES];
				}
			});
		}
	}
	
}

@end
