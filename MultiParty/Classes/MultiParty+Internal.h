//
//  MultiParty+Internal.h
//  MultiParty
//

#import <Foundation/Foundation.h>


#import <SkyWay/SKWPeer.h>
#import <SkyWay/SKWMediaStream.h>

//#import "NSObject+cancelable_block.h"

#import "MultiParty.h"
#import "MultiPartyOption+Internal.h"
#import "MultiPartyError+Internal.h"

@interface MultiParty ()
{
	// Local variables
	BOOL					_bStarting;
	MultiPartyOption*		_mpOption;
	
	SKWPeer*				_peer;
	SKWMediaStream*			_msLocal;
	
	NSMutableDictionary*	_peers;
	
	NSOperationQueue*		_oqListing;
	NSOperationQueue*		_oqCallback;
	
	NSCondition*			_cndWait;
	
	NSCondition*			_cndPolling;
	NSThread*				_thrPolling;
	BOOL					_bPolling;
	
	// Blocks
	void					(^_blkOpen)(NSDictionary *);
	
	void					(^_blkMSMy)(NSDictionary *);
	void					(^_blkMSPeer)(NSDictionary *);
	void					(^_blkMSClose)(NSDictionary *);
	void					(^_blkSSPeer)(NSDictionary *);
	void					(^_blkSSClose)(NSDictionary *);
	
	void					(^_blkDCOpen)(NSDictionary *);
	void					(^_blkDCMessage)(NSDictionary *);
	void					(^_blkDCClose)(NSDictionary *);
	
	void					(^_blkError)(NSDictionary *);
}

@property (nonatomic) BOOL opened;							/// Open status.
@property (nonatomic) MultiPartyDebugLevelEnum debugLevel;	/// Debug level.

/**
 Calling block with NSDictionary object
 @param dictionary Parameter
 @param event MultiParty event type
 */
- (void)callBlockWithDictionary:(NSDictionary *)dictionary event:(MultiPartyEventEnum)event;

/**
 */
- (void)signalToCondition;

/**
 */
- (NSObject *)getObjectFromJSONString:(NSString *)strJson withKey:(NSString *)strKey;

@end
