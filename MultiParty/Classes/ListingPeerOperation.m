//
//  ListingPeerOperation.m
//  MultiParty
//

#import "ListingPeerOperation.h"

@interface ListingPeerOperation ()
{
	SKWPeer*			_peer;
	NSString*			_strOwnId;
	NSString*			_strRoomId;
	
	void				(^_blkListing)(NSArray *);
}

@end

@implementation ListingPeerOperation

- (instancetype)init
{
	self = [super init];
	if (nil == self)
	{
		return nil;
	}
	
	_peer = nil;
	_strOwnId = @"";
	_strRoomId = @"";
	_blkListing = nil;
	
	return self;
}

- (void)setPeer:(SKWPeer *)peer
{
	_peer = peer;
}

- (void)setOwnPeerId:(NSString *)peerId
{
	_strOwnId = peerId;
}

- (void)setRoomId:(NSString *)roomId
{
	_strRoomId = roomId;
}

- (void)setListingResultBlock:(void (^)(NSArray *))block
{
	_blkListing = block;
}

- (void)start
{
	if ((nil == _peer) || (nil == _blkListing))
	{
		return;
	}
	
	[_peer listAllPeers:^(NSArray* peers) {
		NSMutableArray* maryResult = [[NSMutableArray alloc] init];
		
		for (NSString* strPeer in peers)
		{
			if ([strPeer isEqualToString:_strOwnId])
			{
				// Own Id
				continue;
			}
			
			if ([_strRoomId length] > [strPeer length])
			{
				// Other peer
				continue;
			}
			
			// Room Id
			NSRange rng = NSMakeRange(0, [_strRoomId length]);
			if (NSOrderedSame == [strPeer compare:_strRoomId options:0 range:rng])
			{
				[maryResult addObject:strPeer];
			}
		}
		
		if (nil != _blkListing)
		{
			_blkListing(maryResult);
		}
	}];
}

@end
