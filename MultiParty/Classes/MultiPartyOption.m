//
//  MultiPartyOption.m
//  MultiParty
//

#import "MultiPartyOption+Internal.h"


@implementation MultiPartyOption


- (instancetype)init
{
	self = [super init];
	if (nil == self)
	{
		return nil;
	}

	// For get default value
	SKWPeerOption* defOption = [[SKWPeerOption alloc] init];
	
	self.key = @"";
	self.domain = [defOption domain];
	self.room = @"";
	self.identity = @"";
	self.reliable = NO;
	self.serialization = MP_SERIALIZATION_BINARY;
	self.constraints = [[SKWMediaConstraints alloc] init];
	self.polling = NO;
	self.polling_interval = 3000;
	self.polling_autoreconnect = NO;
	self.debug = MP_DEBUG_LEVEL_NO_LOGS;
	self.locationHost = @"";
	self.locationPath = @"";
	self.host = [defOption host];
	self.port = [defOption port];
	self.secure = [defOption secure];
	self.config = [defOption config];
	self.useSkyWayTurn = [defOption turn];
	self.useH264 = [defOption useH264];
	
	self.room_id = nil;
	self.room_name = nil;
	self.peerOption = nil;
	
	return self;
}

- (NSString *)description
{
	NSMutableString* mstr = [[NSMutableString alloc] init];
	
	[mstr appendString:@"key="];
	if (nil != _key)
	{
		[mstr appendString:_key];
	}
	
	[mstr appendString:@" domain="];
	if (nil != _domain)
	{
		[mstr appendString:_domain];
	}
	
	[mstr appendString:@" room="];
	if (nil != _room)
	{
		[mstr appendString:_room];
	}
	
	[mstr appendString:@" identity="];
	if (nil != _identity)
	{
		[mstr appendString:_identity];
	}
	
	[mstr appendString:@" reliable="];
	if (NO == _reliable)
	{
		[mstr appendString:@"NO"];
	}
	else if (YES == _reliable)
	{
		[mstr appendString:@"YES"];
	}
	
	[mstr appendString:@" serialization="];
	if (MP_SERIALIZATION_BINARY == _serialization)
	{
		[mstr appendString:@"binary"];
	}
	else if (MP_SERIALIZATION_BINARY_UTF8 == _serialization)
	{
		[mstr appendString:@"binary-utf8"];
	}
	else if (MP_SERIALIZATION_JSON == _serialization)
	{
		[mstr appendString:@"json"];
	}
	else if (MP_SERIALIZATION_NONE == _serialization)
	{
		[mstr appendString:@"none"];
	}
	
	[mstr appendString:@" constraints="];
	if (nil != _constraints)
	{
		NSString* strDesc = [NSString stringWithFormat:@"{%@}", _constraints];
		[mstr appendString:strDesc];
	}
	
	[mstr appendString:@" polling="];
	if (NO == _polling)
	{
		[mstr appendString:@"NO"];
	}
	else if (YES == _polling)
	{
		[mstr appendString:@"YES"];
	}
	
	[mstr appendString:@" polling_interval="];
	{
		NSString* strValue = [NSString stringWithFormat:@"%0d", (int)_polling_interval];
		[mstr appendString:strValue];
	}
	
	[mstr appendString:@" polling_autoreconnect="];
	if (NO == _polling_autoreconnect)
	{
		[mstr appendString:@"NO"];
	}
	else if (YES == _polling_autoreconnect)
	{
		[mstr appendString:@"YES"];
	}
	
	[mstr appendString:@" debug="];
	if (MP_DEBUG_LEVEL_NO_LOGS == _debug)
	{
		[mstr appendString:@"NoLogs"];
	}
	else if (MP_DEBUG_LEVEL_ONLY_ERROR == _debug)
	{
		[mstr appendString:@"OnlyError"];
	}
	else if (MP_DEBUG_LEVEL_ERROR_AND_WARNING == _debug)
	{
		[mstr appendString:@"ErrorAndWarning"];
	}
	else if (MP_DEBUG_LEVEL_ALL_LOGS == _debug)
	{
		[mstr appendString:@"AllLogs"];
	}
	
	[mstr appendString:@" host="];
	if (nil != _host)
	{
		[mstr appendString:_host];
	}
	
	[mstr appendString:@" port="];
	{
		NSString* strValue = [NSString stringWithFormat:@"%0d", (int)_port];
		[mstr appendString:strValue];
	}
	
	[mstr appendString:@" secure="];
	if (NO == _secure)
	{
		[mstr appendString:@"NO"];
	}
	else if (YES == _secure)
	{
		[mstr appendString:@"YES"];
	}
	
	[mstr appendString:@" config="];
	if (nil != _config)
	{
		NSString* strValue = [NSString stringWithFormat:@"%@", _config];
		[mstr appendString:strValue];
	}

	[mstr appendString:@" useSkyWayTurn="];
	if (NO == _useSkyWayTurn)
	{
		[mstr appendString:@"NO"];
	}
	else if (YES == _useSkyWayTurn)
	{
		[mstr appendString:@"YES"];
	}
	
	[mstr appendString:@" useH264="];
	if (NO == _useH264)
	{
		[mstr appendString:@"NO"];
	}
	else if (YES == _useH264)
	{
		[mstr appendString:@"YES"];
	}
	
	return mstr;
}

@end
