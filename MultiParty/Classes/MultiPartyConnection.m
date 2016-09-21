//
//  MultiPartyConnection.m
//  MultiParty
//

#import "MultiPartyConnection.h"

#import "MultiPartyOption+Internal.h"

@implementation MultiPartyConnection

- (instancetype)init
{
	self = [super init];
	if (nil == self)
	{
		return nil;
	}
	
	self.medias = [[NSMutableArray alloc] init];
	self.datas = [[NSMutableArray alloc] init];
	
	return self;
}

/**
 Close connections
 */
- (void)close
{
	// Close data connection
	while (0 < [_datas count])
	{
		SKWDataConnection* data = [_datas objectAtIndex:0];
		
		[self removeDataConnection:data];
	}
	
	[_datas removeAllObjects];
	self.datas = nil;
	
	// Close media connection
	while (0 < [_medias count])
	{
		SKWMediaConnection* media = [_medias objectAtIndex:0];
		
		[self removeMediaConnection:media];
	}
	
	[_medias removeAllObjects];
	self.medias = nil;
	
	self.multiparty = nil;
	self.peer = nil;
}

/**
 Add media connection
 */
- (void)addMediaConnection:(SKWMediaConnection *)media
{
	if (nil == media)
	{
		return;
	}

	[_medias addObject:media];
	
	[media on:SKW_MEDIACONNECTION_EVENT_STREAM callback:^(NSObject* obj) {
		if ((nil != self) && (nil != _multiparty))
		{
			BOOL bScreenShare = NO;
			SKWMediaStream* stream = (SKWMediaStream *)obj;
			
			if (MP_DEBUG_LEVEL_ALL_LOGS <= [self.multiparty debugLevel])
			{
				NSLog(@"[MP/MEDIA/Add]%@", stream);
			}
			
			SKWMediaConnection* connection = [self findMediaConnection:stream];
			
			if (nil != connection)
			{
				NSObject* objValue = [self.multiparty getObjectFromJSONString:connection.metadata withKey:@"type"];
				if ((nil != objValue) && (YES == [objValue isKindOfClass:[NSString class]]))
				{
					NSString* strValue = (NSString *)objValue;

					if ((nil != strValue) && (YES == [strValue isEqualToString:@"screen"]))
					{
						bScreenShare = YES;
					}
				}
			}
			
			NSDictionary* dic = @{
								  @"id" : _peer,
								  @"src" : obj,
								  };
			
			if (NO == bScreenShare)
			{
				// Normal media stream
				[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_PEER_MS];
			}
			else
			{
				// Screen share media stream
				[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_PEER_SS];
			}
		}
	}];
	
	[media on:SKW_MEDIACONNECTION_EVENT_REMOVE_STREAM callback:^(NSObject* obj) {
		if ((nil != self) && (nil != _multiparty))
		{
			BOOL bScreenShare = NO;
			SKWMediaStream* stream = (SKWMediaStream *)obj;
			
			if (MP_DEBUG_LEVEL_ALL_LOGS <= _multiparty.debugLevel)
			{
				NSLog(@"[MP/MEDIA/Remove]%@", stream);
			}

			SKWMediaConnection* connection = [self findMediaConnection:stream];
			
			NSDictionary* dic = @{
								  @"id" : _peer,
								  @"src" : obj,
								  };
			
			if (nil != connection)
			{
				NSObject* objValue = [_multiparty getObjectFromJSONString:connection.metadata withKey:@"type"];
				if ((nil != objValue) && (YES == [objValue isKindOfClass:[NSString class]]))
				{
					NSString* strValue = (NSString *)objValue;

					if ((nil != strValue) && (YES == [strValue isEqualToString:@"screen"]))
					{
						bScreenShare = YES;
					}
				}
			}

			if (NO == bScreenShare)
			{
				// Normal media stream
				[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_MS_CLOSE];
			}
			else
			{
				// Screen share media stream
				[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_SS_CLOSE];
			}
		}
	}];
	
	[media on:SKW_MEDIACONNECTION_EVENT_CLOSE callback:^(NSObject* obj) {
		if (nil != self)
		{
			if (YES == [obj isKindOfClass:[SKWMediaConnection class]])
			{
				SKWMediaConnection* connection = (SKWMediaConnection *)obj;
				[self removeMediaConnection:connection];
			}
		}
	}];
	
	[media on:SKW_MEDIACONNECTION_EVENT_ERROR callback:^(NSObject* obj) {
		if ((nil != self) && (nil != _multiparty))
		{
			NSDictionary* dic = @{
								  @"id" : _peer,
								  @"error" : obj,
								  };
			
			[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_ERROR];
		}
	}];
}

/**
 Remove media connection
 */
- (void)removeMediaConnection:(SKWMediaConnection *)media
{
	if (nil == media)
	{
		return;
	}
	
	if (YES == [media isOpen])
	{
		[media close];
	}
	
	[media on:SKW_MEDIACONNECTION_EVENT_STREAM callback:nil];
	[media on:SKW_MEDIACONNECTION_EVENT_REMOVE_STREAM callback:nil];
	[media on:SKW_MEDIACONNECTION_EVENT_CLOSE callback:nil];
	[media on:SKW_MEDIACONNECTION_EVENT_ERROR callback:nil];
	
	[_medias removeObject:media];
}

/**
 */
- (SKWMediaConnection *)findMediaConnection:(SKWMediaStream *)stream
{
	SKWMediaConnection* media = nil;

	SEL selector = NSSelectorFromString(@"getRemoteStreams");

	for (SKWMediaConnection* connection in _medias)
	{
		IMP method = [connection methodForSelector:selector];
		NSArray* aryValues = ((NSArray* (*)(id, SEL))method)(connection, selector);

		if ((nil == aryValues) || (0 == [aryValues count]))
		{
			continue;
		}

		for (SKWMediaStream* remoteStream in aryValues)
		{
			if (stream == remoteStream)
			{
				media = connection;
				break;
			}
		}

		if (nil != media)
		{
			break;
		}
	}

	return media;
}

/**
 Add data connection
 */
- (void)addDataConnection:(SKWDataConnection *)data
{
	if (nil == data)
	{
		return;
	}
	
	[_datas addObject:data];

	[data on:SKW_DATACONNECTION_EVENT_OPEN callback:^(NSObject* obj) {
		if ((nil != self) && (nil != _multiparty))
		{
			if (YES == [obj isKindOfClass:[SKWDataConnection class]])
			{
				SKWDataConnection* connection = (SKWDataConnection *)obj;
				if (MP_DEBUG_LEVEL_ALL_LOGS <= _multiparty.debugLevel)
				{
					NSLog(@"[MP/DATA/Open]%@", connection);
				}
			}
			
			NSDictionary* dic = @{
								  @"id" : _peer,
								  };
			
			[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_DC_OPEN];
		}
	}];
	
	[data on:SKW_DATACONNECTION_EVENT_DATA callback:^(NSObject* obj) {
		if ((nil != self) && (nil != _multiparty))
		{
			NSDictionary* dic = @{
								  @"id" : _peer,
								  @"data" : obj,
								  };
			
			[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_MESSAGE];
		}
	}];

	[data on:SKW_DATACONNECTION_EVENT_CLOSE callback:^(NSObject* obj) {
		if ((nil != self) && (nil != _multiparty))
		{
			if (YES == [obj isKindOfClass:[SKWDataConnection class]])
			{
				SKWDataConnection* connection = (SKWDataConnection *)obj;
				if (MP_DEBUG_LEVEL_ALL_LOGS <= _multiparty.debugLevel)
				{
					NSLog(@"[MP/DATA/Close]%@", connection);
				}
			}
			
			NSDictionary* dic = @{
								  @"id" : _peer,
								  };
			
			[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_DC_CLOSE];
			
			if (YES == [obj isKindOfClass:[SKWDataConnection class]])
			{
				SKWDataConnection* connection = (SKWDataConnection *)obj;
				
				[self removeDataConnection:connection];
			}
		}
	}];

	[data on:SKW_DATACONNECTION_EVENT_ERROR callback:^(NSObject* obj) {
		if ((nil != self) && (nil != _multiparty))
		{
			NSDictionary* dic = @{
								  @"id" : _peer,
								  @"error" : obj,
								  };
			if (nil != _multiparty)
			{
				[_multiparty callBlockWithDictionary:dic event:MULTIPARTY_EVENT_ERROR];
			}
		}
	}];
}

/**
 Remove data connection
 */
- (void)removeDataConnection:(SKWDataConnection *)data
{
	if (nil == data)
	{
		return;
	}
	
	if (YES == [data isOpen])
	{
		[data close];
	}
	
	[data on:SKW_DATACONNECTION_EVENT_ERROR callback:nil];
	[data on:SKW_DATACONNECTION_EVENT_CLOSE callback:nil];
	[data on:SKW_DATACONNECTION_EVENT_DATA callback:nil];
	[data on:SKW_DATACONNECTION_EVENT_OPEN callback:nil];
	
	[_datas removeObject:data];
}

@end
