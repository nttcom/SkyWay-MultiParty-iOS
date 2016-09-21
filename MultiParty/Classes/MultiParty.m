//
//  MultiParty.m
//  MultiParty
//

#import "MultiParty+Internal.h"


#import <CommonCrypto/CommonCrypto.h>

#import "MultiPartyConnection.h"

#import "ListingPeerOperation.h"
#import "CallbackOperation.h"


@implementation MultiParty

#pragma mark - public

/**
 Intialize object
 */
- (instancetype)initWithOption:(MultiPartyOption *)option
{
	self = [super init];
	if (nil == self)
	{
		return nil;
	}
	
	// Public property / variables
	_opened = NO;
	_reconnecting = NO;
	
	// Private property / variables
	_bStarting = NO;
	
	_oqListing = [[NSOperationQueue alloc] init];
	_oqCallback = [[NSOperationQueue alloc] init];
	
	_peers = [[NSMutableDictionary alloc] init];
	
	_cndWait = [[NSCondition alloc] init];
	_cndPolling = [[NSCondition alloc] init];

	// MultiParty option
	_mpOption = option;
	
	_debugLevel = [option debug];
	
	// Set peer option
	SKWPeerOption* peerOption = [[SKWPeerOption alloc] init];
	[peerOption setType:SKW_PEER_TYPE_SKYWAY];
	[peerOption setKey:[_mpOption key]];
	[peerOption setDomain:[_mpOption domain]];
	
	SKWDebugLevelEnum debugLevel = SKW_DEBUG_LEVEL_NO_LOGS;
	if (MP_DEBUG_LEVEL_NO_LOGS == [_mpOption debug])
	{
		debugLevel = SKW_DEBUG_LEVEL_NO_LOGS;
	}
	else if (MP_DEBUG_LEVEL_ONLY_ERROR == [_mpOption debug])
	{
		debugLevel = SKW_DEBUG_LEVEL_ONLY_ERROR;
	}
	else if (MP_DEBUG_LEVEL_ERROR_AND_WARNING == [_mpOption debug])
	{
		debugLevel = SKW_DEBUG_LEVEL_ERROR_AND_WARNING;
	}
	else if (MP_DEBUG_LEVEL_ALL_LOGS == [_mpOption debug])
	{
		debugLevel = SKW_DEBUG_LEVEL_ALL_LOGS;
	}
	[peerOption setDebug:debugLevel];

	[peerOption setHost:[_mpOption host]];
	[peerOption setPort:[_mpOption port]];
	[peerOption setSecure:[_mpOption secure]];
	[peerOption setConfig:[_mpOption config]];
	[peerOption setTurn:[_mpOption useSkyWayTurn]];
	[peerOption setUseH264:[_mpOption useH264]];
	
	[_mpOption setPeerOption:peerOption];

	// Check using stream
	[_mpOption setUse_stream:NO];
	if ((YES == [_mpOption.constraints videoFlag]) || (YES == [_mpOption.constraints audioFlag]))
	{
		[_mpOption setUse_stream:YES];
	}
	
	// Generate room_name and room_id
	NSString* strSeed = @"";
	if (nil != [_mpOption room])
	{
		strSeed = [_mpOption room];
	}

	NSError* error = nil;
	NSRange rng = NSMakeRange(0, [strSeed length]);
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"/^[0-9a-zA-Z\\-\\_]{4,32}$/" options:NSRegularExpressionCaseInsensitive error:&error];
	NSString* strResult = [regex stringByReplacingMatchesInString:strSeed options:NSMatchingReportProgress range:rng withTemplate:@""];
	
	[_mpOption setRoom_name:strResult];
	
	NSString* strRoomId = [self makeRoomName:strSeed];
	[_mpOption setRoom_id:strRoomId];
	
	// Hash
	NSString* strPeerId = nil;
	if ((nil == [_mpOption identity]) || (0 == [_mpOption.identity length]))
	{
		NSString* strGenId = [self makeID];
		strPeerId = [NSString stringWithFormat:@"%@%@", [_mpOption room_id], strGenId];
	}
	else
	{
		strPeerId = [NSString stringWithFormat:@"%@%@", [_mpOption room_id], [_mpOption identity]];
	}
	[_mpOption setIdentity:strPeerId];
	
	return self;
}

/**
 Start multiparty
 */
- (void)start
{
	if (_bStarting)
	{
		return;
	}
	
	_bStarting = YES;
	
	dispatch_queue_t queue = dispatch_get_main_queue();
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), queue, ^{
		[self connectToSkyWay];
	});
}

/**
 Set event block
 */
- (void)on:(MultiPartyEventEnum)event callback:(void (^)(NSDictionary *))callback
{
	if (MULTIPARTY_EVENT_OPEN == event)
	{
		// Open
		_blkOpen = callback;
	}
	else if (MULTIPARTY_EVENT_MY_MS == event)
	{
		// Open own media stream
		_blkMSMy = callback;
	}
	else if (MULTIPARTY_EVENT_PEER_MS == event)
	{
		// Open remote media stream
		_blkMSPeer = callback;
	}
	else if (MULTIPARTY_EVENT_MS_CLOSE == event)
	{
		// Close media stream
		_blkMSClose = callback;
	}
	else if (MULTIPARTY_EVENT_PEER_SS == event)
	{
		// Open remote screen cast stream
		_blkSSPeer = callback;
	}
	else if (MULTIPARTY_EVENT_SS_CLOSE == event)
	{
		// Close remote screen cast stream
		_blkSSClose = callback;
	}
	else if (MULTIPARTY_EVENT_DC_OPEN == event)
	{
		// Open remote data channel
		_blkDCOpen = callback;
	}
	else if (MULTIPARTY_EVENT_MESSAGE == event)
	{
		// Incoming remote data
		_blkDCMessage = callback;
	}
	else if (MULTIPARTY_EVENT_DC_CLOSE == event)
	{
		// Close remote data channel
		_blkDCClose = callback;
	}
	else if (MULTIPARTY_EVENT_ERROR == event)
	{
		// Rise error
		_blkError = callback;
	}
}

/**
 Mute local video and audio
 */
- (void)muteVideo:(BOOL)video audio:(BOOL)audio
{
	[self muteLocalMediaStreamWithVideo:video audio:audio];
}

/**
 Remove remote
 */
- (BOOL)removePeer:(NSString *)peerId
{
	if (nil == _peer)
	{
		return NO;
	}

	SEL selCleanup = NSSelectorFromString(@"cleanupWithPeer:");
	if (YES == [_peer respondsToSelector:selCleanup])
	{
		[_peer performSelector:selCleanup withObject:peerId afterDelay:0.1f];
	}
	
	MultiPartyConnection* connection = _peers[peerId];
	if (nil != connection)
	{
		[connection close];
	}
	
	[_peers removeObjectForKey:peerId];
	
	return YES;
}

/**
 Send data to party member
 */
- (BOOL)send:(NSObject *)data
{
	BOOL bResult = NO;

	
	NSArray* aryKeys = [_peers allKeys];
	for (NSString* strKey in aryKeys)
	{
		MultiPartyConnection* connection = _peers[strKey];
		if (nil == connection)
		{
			continue;
		}

		for (SKWDataConnection* datConnection in [connection datas])
		{
			bResult = [datConnection send:data];
			if (NO == bResult)
			{
				if (nil != _mpOption)
				{
					if (MP_DEBUG_LEVEL_NO_LOGS < [_mpOption debug])
					{
						NSLog(@"[MP/Send/Error]%@", data);
					}
				}
				
				break;
			}
		}
	}
	
	return bResult;
}

/**
 Closing multiparty
 */
- (void)close
{
	if (NO == _opened)
	{
		return;
	}

	_opened = NO;
	_reconnecting = NO;
	
	// Stop polling
	[self signalToCondition];
	
	[self stopPollingConnections];

	if (nil != _cndWait)
	{
		[_cndWait lock];
		[_cndWait signal];
		[_cndWait unlock];
	}
	_cndWait = nil;

	if (nil != _cndPolling)
	{
		[_cndPolling lock];
		[_cndPolling signal];
		[_cndPolling unlock];
	}
	_cndPolling = nil;

	_mpOption = nil;
	
	_bStarting = NO;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), queue, ^{
		if (nil != self)
		{
			[self closing];
		}
	});
}

/**
 Listing room members
 */
- (BOOL)listAllPeers:(void (^)(NSArray *))callback
{
	if ((nil == _peer) || (YES == [_peer isDestroyed]) || (YES == [_peer isDisconnected]) || (nil == _oqListing))
	{
		return NO;
	}
	
	ListingPeerOperation* queue = [[ListingPeerOperation alloc] init];
	[queue setPeer:_peer];
	[queue setOwnPeerId:[_mpOption identity]];
	[queue setRoomId:[_mpOption room_id]];
	[queue setListingResultBlock:callback];

	[_oqListing addOperation:queue];
	
	return YES;
}

/**
 Reconnect connection
 */
- (void)reconnectVideo:(BOOL)video screen:(BOOL)screen data:(BOOL)data
{
	if (YES == _reconnecting)
	{
		return;
	}
	
	[self stopPollingConnections];
	
	BOOL bMedia = video;
	BOOL bData = data;
	BOOL bScreen = screen;
	
	_reconnecting = YES;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[self listAllPeers:^(NSArray* peers) {
			BOOL bConnecting = NO;
			
			for (NSString* peer in peers)
			{
				if (NO == _reconnecting)
				{
					break;
				}
				
				if (YES == bData)
				{
					// Try to data connection
					bConnecting = [self startData:peer];
					if (bConnecting)
					{
						[_cndWait lock];
						[_cndWait wait];
						[_cndWait unlock];
					}
				}
				
				if (NO == _reconnecting)
				{
					break;
				}
				
				if (YES == bMedia)
				{
					// Try to media connection
					bConnecting = [self startMedia:peer useStream:YES];
					if (bConnecting)
					{
						[_cndWait lock];
						[_cndWait wait];
						[_cndWait unlock];
					}
				}
				
				if (NO == _reconnecting)
				{
					break;
				}
				
				if (YES == bScreen)
				{
					// Try to screen share media connection
					bConnecting = [self startMedia:peer useStream:NO];
					if (bConnecting)
					{
						[_cndWait lock];
						[_cndWait wait];
						[_cndWait unlock];
					}
				}
			}
			
			_reconnecting = NO;
			
			if (YES == [_mpOption polling])
			{
				[self startPollingConnections];
			}
		}];
	});
}

#pragma mark - Internal

- (void)closingLocal
{
	// Closing local media stream
	if (nil != _msLocal)
	{
		[_msLocal close];
		_msLocal = nil;
	}
	
	[SKWNavigator terminate];
	
	if (nil != _peer)
	{
		[_peer destroy];
		_peer = nil;
	}
}

- (void)closing
{
	// Clear peer blocks
	[self clearBlocks];
	
	// Canceling Peer listing
	if (nil != _oqListing)
	{
		[_oqListing cancelAllOperations];
		_oqListing = nil;
	}

	// Disconnect remote connections
	if (nil != _peers)
	{
		for (NSString* strKey in [_peers allKeys])
		{
			MultiPartyConnection* connection = (MultiPartyConnection *)[_peers objectForKey:strKey];
			if (nil != connection)
			{
				[connection close];
			}
		}
		
		[_peers removeAllObjects];
	}
	
	if (nil != self)
	{
		[self closingLocal];
	}
}

/**
 Calling block with NSDictionary object
 */
- (void)callBlockWithDictionary:(NSDictionary *)dictionary event:(MultiPartyEventEnum)event
{
	void (^block)(NSDictionary *) = nil;
	
	if (MULTIPARTY_EVENT_OPEN == event)
	{
		// Open
		block = _blkOpen;
	}
	else if (MULTIPARTY_EVENT_MY_MS == event)
	{
		// Own local media stream
		block = _blkMSMy;
	}
	else if (MULTIPARTY_EVENT_PEER_MS == event)
	{
		// Incoming remote media stream
		block = _blkMSPeer;
	}
	else if (MULTIPARTY_EVENT_MS_CLOSE == event)
	{
		// Close remote media stream
		block = _blkMSClose;
	}
	else if (MULTIPARTY_EVENT_PEER_SS == event)
	{
		// Incoming screen cast stream
		block = _blkSSPeer;
	}
	else if (MULTIPARTY_EVENT_SS_CLOSE == event)
	{
		// Close screen cast stream
		block = _blkSSClose;
	}
	else if (MULTIPARTY_EVENT_DC_OPEN == event)
	{
		// Open data connection
		block = _blkDCOpen;
	}
	else if (MULTIPARTY_EVENT_MESSAGE == event)
	{
		// Incoming data
		block = _blkDCMessage;
	}
	else if (MULTIPARTY_EVENT_DC_CLOSE == event)
	{
		// Close data connection
		block = _blkDCClose;
	}
	else if (MULTIPARTY_EVENT_ERROR == event)
	{
		// Error
		block = _blkError;
	}

	if (nil != _cndWait)
	{
		[_cndWait lock];
		[_cndWait signal];
		[_cndWait unlock];
	}
	
	if (nil == block)
	{
		return;
	}
	
	CallbackOperation* op = [[CallbackOperation alloc] init];
	[op setMultiParty:self];
	[op setEventType:event];
	[op setCallbackBlock:block];
	[op setCallbackParam:dictionary];
	
	[_oqCallback addOperation:op];
}

#pragma mark - Private

/**
 Set peer events
 @param peer Peer object
 */
- (void)setPeerEvents:(SKWPeer *)peer
{
	if (nil == peer)
	{
		return;
	}
	
	[_peer on:SKW_PEER_EVENT_OPEN callback:^(NSObject* peerId) {
		// Open
		if (YES == [peerId isKindOfClass:[NSString class]])
		{
			NSString* strPeerId = (NSString *)peerId;
			
			if (NO == [self opened])
			{
				[self setOpened:YES];
			}
			
			if (YES == [strPeerId isEqualToString:[_mpOption identity]])
			{
				NSDictionary* dic = @{
									  @"id": strPeerId,
									  };
				
				[self callBlockWithDictionary:dic event:MULTIPARTY_EVENT_OPEN];
				
				dispatch_time_t tm = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC));
				dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
				dispatch_after(tm, queue, ^{
					// Start local media connection
					if (YES == [_mpOption use_stream])
					{
						[self startMediaStream];
					}
					
					// Get room peers
					[self getIDs];
				});
			}
		}
	}];
	
	[_peer on:SKW_PEER_EVENT_CALL callback:^(NSObject* obj) {
		// Call
		if (YES == [obj isKindOfClass:[SKWMediaConnection class]])
		{
			SKWMediaConnection* media = (SKWMediaConnection *)obj;
			
			// Remote peer id
			NSString* strPeerId = [media peer];
			
			MultiPartyConnection* connection = _peers[strPeerId];

			if (nil == connection)
			{
				connection = [[MultiPartyConnection alloc] init];
				[connection setMultiparty:self];
				[connection setPeer:strPeerId];
				
				_peers[strPeerId] = connection;
			}

			// add media connection
			[connection addMediaConnection:media];

			// Check media connection meta data
			BOOL bAnswered = NO;
			
			NSObject* objValue = [self getObjectFromJSONString:[media metadata] withKey:@"type"];
			if ((nil != objValue) && (YES == [objValue isKindOfClass:[NSString class]]))
			{
				NSString* strValue = (NSString *)objValue;
				
				if (YES == [strValue isEqualToString:@"screen"])
				{
					// Answer with no media stream
					[media answer];
					
					bAnswered = YES;
				}
			}
			
			if (NO == bAnswered)
			{
				if (NO == [_mpOption use_stream])
				{
					// Answer with no media stream
					[media answer];
				}
				else
				{
					// Answer with media stream
					[media answer:_msLocal];
				}
			}
		}
	}];
	
	[_peer on:SKW_PEER_EVENT_CONNECTION callback:^(NSObject* obj) {
		// Connection
		if (YES == [obj isKindOfClass:[SKWDataConnection class]])
		{
			SKWDataConnection* data = (SKWDataConnection *)obj;
			
			NSString* strPeerId = [data peer];
			
			MultiPartyConnection* connection = _peers[strPeerId];
			if (nil == connection)
			{
				connection = [[MultiPartyConnection alloc] init];
				[connection setMultiparty:self];
				[connection setPeer:strPeerId];
				
				_peers[strPeerId] = connection;
			}
			
			[connection addDataConnection:data];
		}
	}];
	
	[_peer on:SKW_PEER_EVENT_CLOSE callback:^(NSObject* obj) {
		// Closed
		
		// TODO: Codes
	}];
	
	[_peer on:SKW_PEER_EVENT_DISCONNECTED callback:^(NSObject* obj) {
		// Disconnected
		
		// TODO: Codes
	}];
	
	[_peer on:SKW_PEER_EVENT_ERROR callback:^(NSObject* obj) {
		// Error
		NSString* strPeerId = [_peer identity];
		if (nil == strPeerId)
		{
			strPeerId = @"";
		}
		
		SKWPeerError* peerError = nil;
		if (YES == [obj isKindOfClass:[SKWPeerError class]])
		{
			peerError = (SKWPeerError *)obj;
		}
		
		NSMutableDictionary* mdic = [[NSMutableDictionary alloc] init];
		
		mdic[@"id"] = strPeerId;
		if (nil != peerError)
		{
			mdic[@"PeerError"] = peerError;
		}
		
		[self callBlockWithDictionary:mdic event:MULTIPARTY_EVENT_ERROR];
	}];
}

/**
 Clear peer events
 @param peer Peer object
 */
- (void)clearPeerEvents:(SKWPeer *)peer
{
	if (nil == peer)
	{
		return;
	}
	
	[peer on:SKW_PEER_EVENT_ERROR callback:nil];
	[peer on:SKW_PEER_EVENT_DISCONNECTED callback:nil];
	[peer on:SKW_PEER_EVENT_CLOSE callback:nil];
	[peer on:SKW_PEER_EVENT_CONNECTION callback:nil];
	[peer on:SKW_PEER_EVENT_CALL callback:nil];
	[peer on:SKW_PEER_EVENT_OPEN callback:nil];
}

/**
 Clear blocks
 */
- (void)clearBlocks
{
	_blkError = nil;
	
	_blkDCClose = nil;
	_blkDCMessage = nil;
	_blkDCOpen = nil;
	
	_blkSSClose = nil;
	_blkSSPeer = nil;
	
	_blkMSClose = nil;
	_blkMSPeer = nil;
	_blkMSMy = nil;
	
	_blkOpen = nil;
}

/**
 Connecting to SkyWay signaling server.
 */
- (void)connectToSkyWay
{
	// create peer
	_peer = [[SKWPeer alloc] initWithId:[_mpOption identity] options:[_mpOption peerOption]];
	
	[self setPeerEvents:_peer];
}

/**
 Get already connected remote peer IDs.
 */
- (void)getIDs
{
	[self listAllPeers:^(NSArray* peers) {
		if (nil != self)
		{
			for (NSString* peer in peers)
			{
				MultiPartyConnection* connection = _peers[peer];
				if (nil == connection)
				{
					connection = [[MultiPartyConnection alloc] init];
					[connection setPeer:peer];
					[connection setMultiparty:self];
					
					_peers[peer] = connection;
				}
			}
			
			if (YES == [_mpOption use_stream])
			{
				while (nil == _msLocal)
				{
					[_cndWait lock];
					[_cndWait wait];
					[_cndWait unlock];
				}
				
				[self startMediaConnections];
			}
			
			// Start data connection
			[self startDataConnections];
			
			// Start polling
			if (YES == [_mpOption polling])
			{
				[self startPollingConnections];
			}
		}
	}];
}

/**
 Start polling connections
 */
- (void)startPollingConnections
{
	if ((YES == _bPolling) || (nil == _cndPolling))
	{
		return;
	}
	
	_bPolling = YES;
	
	if (nil == _thrPolling)
	{
		_thrPolling = [[NSThread alloc] initWithTarget:self selector:@selector(polling) object:nil];
		[_thrPolling start];
	}
}

/**
 Stop polling connections
 */
- (void)stopPollingConnections
{
	if ((NO == _bPolling) || (nil == _cndPolling))
	{
		return;
	}
	
	_bPolling = NO;
	
	[_thrPolling cancel];
	
	[_cndPolling lock];
	[_cndPolling signal];
	[_cndPolling unlock];
}

/**
 Polling thread
 */
- (void)polling
{
	NSThread* thr = [NSThread currentThread];
	
	while (_bPolling)
	{
		if ((nil != thr) && (YES == [thr isCancelled]))
		{
			break;
		}
		
		NSTimeInterval ti = (NSTimeInterval)[_mpOption polling_interval];
		ti /= 1000.0f;
		
		@autoreleasepool
		{
			NSDate* date = [NSDate dateWithTimeIntervalSinceNow:ti];
			
			[_cndPolling lock];
			[_cndPolling waitUntilDate:date];
			[_cndPolling unlock];
		}
		
		if (YES == _reconnecting)
		{
			continue;
		}
		
		if ((NO == _bPolling) || ((nil != thr) && (YES == [thr isCancelled])))
		{
			break;
		}
		
		[self listAllPeers:^(NSArray* peers) {
			if (nil == peers)
			{
				peers = @[];
			}
			
			if (_bPolling)
			{
				NSMutableArray* maryRemovePeer = [[NSMutableArray alloc] init];
				
				// Check available connections
				NSArray* aryKeys = [_peers allKeys];
				for (NSString* peerId in aryKeys)
				{
					BOOL bFound = NO;
					
					for (NSString* peerAvailable in peers)
					{
						if (YES == [peerId isEqualToString:peerAvailable])
						{
							bFound = YES;
							break;
						}
					}
					
					if (NO == bFound)
					{
						[maryRemovePeer addObject:peerId];
					}
				}
				
				// Closing connections
				for (NSString* peerId in maryRemovePeer)
				{
					MultiPartyConnection* connection = _peers[peerId];
					if (nil != connection)
					{
						[connection close];
					}
				}
				
				[maryRemovePeer removeAllObjects];
			}
			
			[_cndPolling lock];
			[_cndPolling signal];
			[_cndPolling unlock];
		}];
		
		[_cndPolling lock];
		[_cndPolling wait];
		[_cndPolling unlock];
	}
	
	if (nil != _oqListing)
	{
		[_oqListing cancelAllOperations];
	}
	
	_cndPolling = nil;
	_thrPolling = nil;
}

/**
 Get local media stream and start calling
 */
- (void)startMyStream
{
	if (nil == _msLocal)
	{
		SKWMediaConstraints* constraints = nil;
		
		if ((nil != _mpOption) && (nil != _mpOption.constraints))
		{
			constraints = _mpOption.constraints;
		}
		
		if (nil == constraints)
		{
			constraints = [[SKWMediaConstraints alloc] init];
		}
		
		[SKWNavigator initialize:_peer];
		
		_msLocal = [SKWNavigator getUserMedia:constraints];
	}
	
	NSString* peerId = [_peer identity];
	
	if (nil == _msLocal)
	{
		if (nil != _blkError)
		{
			MultiPartyError* error = [[MultiPartyError alloc] init];
			
			NSDictionary* dic = @{
								  @"id" : peerId,
								  @"error" : error,
								  };

			[self callBlockWithDictionary:dic event:MULTIPARTY_EVENT_ERROR];
		}
	}
	else
	{
		NSDictionary* dic = @{
							  @"src" : _msLocal,
							  @"id" : peerId,
							  };
		[self callBlockWithDictionary:dic event:MULTIPARTY_EVENT_MY_MS];
	}
	
	[self signalToCondition];
}

/**
 */
- (void)startMediaStream
{
	dispatch_queue_t queue = dispatch_get_main_queue();
	dispatch_sync(queue, ^{
		[self startMyStream];
	});
}

/**
 Start data connection
 @param peerId Remote peer Id
 */
- (BOOL)startData:(NSString *)peerId
{
	MultiPartyConnection* connection = _peers[peerId];
	if (nil == connection)
	{
		connection = [[MultiPartyConnection alloc] init];
		[connection setPeer:peerId];
		[connection setMultiparty:self];
		
		_peers[peerId] = connection;
	}
	else
	{
		if (0 < [connection.datas count])
		{
			return NO;
		}
	}
	
	if (MP_DEBUG_LEVEL_ALL_LOGS <= [_mpOption debug])
	{
		NSLog(@"[MP/StartingData]%@", peerId);
	}
	
	// Serialization type
	SKWSerializationEnum serialization = SKW_SERIALIZATION_BINARY;
	if (MP_SERIALIZATION_BINARY == [_mpOption serialization])
	{
		serialization = SKW_SERIALIZATION_BINARY;
	}
	else if (MP_SERIALIZATION_BINARY_UTF8 == [_mpOption serialization])
	{
		serialization = SKW_SERIALIZATION_BINARY_UTF8;
	}
	else if (MP_SERIALIZATION_JSON == [_mpOption serialization])
	{
		serialization = SKW_SERIALIZATION_JSON;
	}
	else if (MP_SERIALIZATION_NONE == [_mpOption serialization])
	{
		serialization = SKW_SERIALIZATION_NONE;
	}
	
	// Connect option
	SKWConnectOption* option = [[SKWConnectOption alloc] init];
	[option setSerialization:serialization];
	[option setReliable:[_mpOption reliable]];

	// Connecting data
	SKWDataConnection* data = [_peer connectWithId:peerId options:option];
	if (nil != data)
	{
		[connection addDataConnection:data];
	}
	
	return YES;
}

/**
 Start data connection
 */
- (void)startDataConnections
{
	// Connecting to remote
	BOOL bConnecting = NO;
	
	NSArray* ary = [_peers allKeys];
	for (NSString* strPeer in ary)
	{
		bConnecting = [self startData:strPeer];
		if (bConnecting)
		{
			[_cndWait lock];
			[_cndWait wait];
			[_cndWait unlock];
		}
	}
}

/**
 Start media connection
 */
- (BOOL)startMedia:(NSString *)peerId useStream:(BOOL)useStream
{
	MultiPartyConnection* connection = _peers[peerId];
	if (nil == connection)
	{
		connection = [[MultiPartyConnection alloc] init];
		[connection setPeer:peerId];
		[connection setMultiparty:self];
		
		_peers[peerId] = connection;
	}
	else
	{
		if (0 < [connection.medias count])
		{
			return NO;
		}
	}
	
	if (MP_DEBUG_LEVEL_ALL_LOGS <= [_mpOption debug])
	{
		NSLog(@"[MP/StartingMedia]%@", peerId);
	}
	
	SKWCallOption* option = [[SKWCallOption alloc] init];
	
	// Calling
	SKWMediaConnection* media = nil;
	if (NO == useStream)
	{
		option.metadata = @"{type:screen}";
		media = [_peer callWithId:peerId stream:nil options:option];
	}
	else
	{
		media = [_peer callWithId:peerId stream:_msLocal options:option];
	}
	if (nil != media)
	{
		[connection addMediaConnection:media];
	}
	
	return YES;
}

/**
 */
- (void)startMediaConnections
{
	BOOL bConnecting = NO;
	
	NSArray* ary = [_peers allKeys];
	for (NSString* strPeer in ary)
	{
		// Starting media connection
		bConnecting = [self startMedia:strPeer useStream:YES];
		if (bConnecting)
		{
			[_cndWait lock];
			[_cndWait wait];
			[_cndWait unlock];
		}
	}
}

/**
 Starting screen share connection
 */
- (void)startScreenShare:(NSString *)peerId
{
	if (MP_DEBUG_LEVEL_ALL_LOGS <= [_mpOption debug])
	{
		NSLog(@"[MP/StartingMedia]%@", peerId);
	}
	
	SKWCallOption* option = [[SKWCallOption alloc] init];
	
	MultiPartyConnection* connection = _peers[peerId];
	if (nil == connection)
	{
		connection = [[MultiPartyConnection alloc] init];
		[connection setPeer:peerId];
		[connection setMultiparty:self];
		
		_peers[peerId] = connection;
	}
	
	if (0 == [connection.medias count])
	{
		// Calling
		[option setMetadata:@"{type:screen}"];
		
		SKWMediaConnection* media = [_peer callWithId:peerId stream:nil options:option];
		if (nil != media)
		{
			[connection addMediaConnection:media];
		}
	}
}

/**
 Change mute state local media stream
 */
- (void)muteLocalMediaStreamWithVideo:(BOOL)video audio:(BOOL)audio
{
	if (nil == _msLocal)
	{
		return;
	}
	
	if (NO == video)
	{
		video = YES;
	}
	else
	{
		video = NO;
	}
	
	if (NO == audio)
	{
		audio = YES;
	}
	else
	{
		audio = NO;
	}
	
	[self enableVideoTrack:_msLocal enable:video];
	[self enableAudioTrack:_msLocal enable:audio];
}

/**
 Change mute state remote media streams
 */
- (void)muteRemoteMediaStreamWithVideo:(BOOL)video audio:(BOOL)audio
{
	// TODO: Codes
}

/**
 Change enable state to video tracks
 */
- (void)enableVideoTrack:(SKWMediaStream *)stream enable:(BOOL)enable
{
	NSUInteger uiCounts = [stream getVideoTracks];
	for (NSUInteger uiIndex = 0 ; uiCounts > uiIndex ; uiIndex++)
	{
		[stream setEnableVideoTrack:uiIndex enable:enable];
	}
}

/**
 Change enable state to audio tracks
 */
- (void)enableAudioTrack:(SKWMediaStream *)stream enable:(BOOL)enable
{
	NSUInteger uiCounts = [stream getAudioTracks];
	for (NSUInteger uiIndex = 0 ; uiCounts > uiIndex ; uiIndex++) {
		[stream setEnableAudioTrack:uiIndex enable:enable];
	}
}

/**
 */
- (void)signalToCondition
{
	[_cndWait lock];
	[_cndWait signal];
	[_cndWait unlock];
}

#pragma mark - Private / Utility

/**
 random token string
 @param uiLen string length
 @return token string
 */
- (NSString *)randomTokenWithLength:(NSUInteger)uiLen
{
	static NSString* strLetters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
	u_int32_t uiLetterLen = (u_int32_t)strLetters.length;
	
	NSMutableString* mstrValue = [[NSMutableString alloc] initWithCapacity:uiLen];
	
	u_int32_t uiLetterPos = 0;
	unichar chValue = 0;
	
	for (NSUInteger uiPos = 0 ; uiLen > uiPos ; uiPos++)
	{
		uiLetterPos = arc4random_uniform(uiLetterLen);
		chValue = [strLetters characterAtIndex:uiLetterPos];
		[mstrValue appendFormat:@"%c", chValue];
	}
	
	return mstrValue;
}

/**
 Calcurate MD5
 @param seed
 @return MD5 value
 */
- (NSString *)calcMD5:(NSString *)seed
{
	unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
	
	NSData* dat = [seed dataUsingEncoding:NSUTF8StringEncoding];
	CC_LONG len = (CC_LONG)[dat length];
	
	CC_MD5([dat bytes], len, md5Buffer);
	
	NSMutableString *mstrValue = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
	{
		[mstrValue appendFormat:@"%02x",md5Buffer[i]];
	}
	
	return mstrValue;
}

/**
 Make ID
 */
- (NSString *)makeID
{
	return [self randomTokenWithLength:32];
}

/**
 Make room name
 @param seed
 @return Room name
 */
- (NSString *)makeRoomName:(NSString *)seed
{
	if (nil == seed)
	{
		seed = @"";
	}
	
	NSMutableString* mstrBase = [[NSMutableString alloc] initWithString:seed];
	NSString* strValue = [_mpOption locationHost];
	if (nil != strValue)
	{
		[mstrBase appendString:strValue];
	}
	strValue = [_mpOption locationPath];
	if (nil != strValue)
	{
		[mstrBase appendString:strValue];
	}
	
	NSString* strMD5 = [self calcMD5:mstrBase];
	
	NSString* strHead = [strMD5 substringToIndex:6];

	return [NSString stringWithFormat:@"%@R_", strHead];
}


- (NSDictionary *)getDictionaryFromJSONString:(NSString *)strJson
{
	if ((nil == strJson) || (0 == [strJson length]))
	{
		return @{};
	}

	NSError* error = nil;
	NSData* datJson = [strJson dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	if ((nil == datJson) || (0 == [datJson length]))
	{
		return @{};
	}
	
	NSDictionary* dicResult = [NSJSONSerialization JSONObjectWithData:datJson options:NSJSONReadingAllowFragments error:&error];
	
	if (nil == dicResult)
	{
		return @{};
	}
	
	return dicResult;
}

- (NSObject *)getObjectFromJSONString:(NSString *)strJson withKey:(NSString *)strKey
{
	if ((nil == strJson) || (0 == [strJson length]))
	{
		return nil;
	}

	NSError* error = nil;
	NSData* datJson = [strJson dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	if ((nil == datJson) || (0 == [datJson length]))
	{
		return nil;
	}
	
	NSDictionary* dicResult = [NSJSONSerialization JSONObjectWithData:datJson options:NSJSONReadingAllowFragments error:&error];
	
	if (nil == dicResult)
	{
		return nil;
	}
	
	return dicResult[strKey];
}

@end
