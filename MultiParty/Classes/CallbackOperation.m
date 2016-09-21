//
//  CallbackOperation.m
//  MultiParty
//

#import "CallbackOperation.h"


@interface CallbackOperation ()
{
	MultiParty*			_multiparty;
	MultiPartyEventEnum	_event;
	NSDictionary*		_dicParam;
	
	void				(^_blkCallback)(NSDictionary *);
}

@end

@implementation CallbackOperation

/**
 Set MultiParty object
 @param multiparty MultiParty object
 */
- (void)setMultiParty:(MultiParty *)multiparty
{
	_multiparty = multiparty;
}

/**
 Set event type
 @param event Event type
 */
- (void)setEventType:(MultiPartyEventEnum)event
{
	_event = event;
}

/**
 Set Parameter
 */
- (void)setCallbackParam:(NSDictionary *)dictionary
{
	_dicParam = dictionary;
}

/**
 Set block
 */
- (void)setCallbackBlock:(void (^)(NSDictionary *))block
{
	_blkCallback = block;
}

/**
 Operation method
 */
- (void)start
{
	if (nil == _blkCallback)
	{
		return;
	}
	
	@autoreleasepool
	{
		_blkCallback(_dicParam);
	}
	
	if (nil != _multiparty)
	{
		if ((MULTIPARTY_EVENT_PEER_MS == _event) || (MULTIPARTY_EVENT_DC_OPEN == _event))
		{
			[_multiparty signalToCondition];
		}
	}
	
	_dicParam = nil;
	_blkCallback = nil;
	_event = 0;
	_multiparty = nil;
}

@end
