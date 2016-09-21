//
//  MultiPartyOption.h
//  MultiParty
//

#import <Foundation/Foundation.h>


#import <SkyWay/SKWIceConfig.h>
#import <SkyWay/SKWMediaConstraints.h>

/**
 Serialization type
 */
typedef NS_ENUM(NSUInteger, MultiPartySerializationEnum)
{
	/// Serialization type / binary
	MP_SERIALIZATION_BINARY,
	/// Serialization type / binary-utf8
	MP_SERIALIZATION_BINARY_UTF8,
	/// Serialization type / json
	MP_SERIALIZATION_JSON,
	/// Serialization type / none
	MP_SERIALIZATION_NONE,
};

/**
 Debug output level
 */
typedef NS_ENUM(NSUInteger, MultiPartyDebugLevelEnum)
{
	/// Debug prints no logs.
	MP_DEBUG_LEVEL_NO_LOGS,
	/// Debug prints only errors.
	MP_DEBUG_LEVEL_ONLY_ERROR,
	/// Debug prints errors and warnings.
	MP_DEBUG_LEVEL_ERROR_AND_WARNING,
	/// Debug prints all logs.
	MP_DEBUG_LEVEL_ALL_LOGS,
};


@interface MultiPartyOption : NSObject

/// SkyWay API Key (Requirements)
@property (nonatomic) NSString* key;
/// Domain related to the SkyWay API Key (Requirements)
@property (nonatomic) NSString* domain;
/// Room name (Default : Empty value)
@property (nonatomic) NSString* room;
/// User ID (Default : Empty value)
@property (nonatomic) NSString* identity;
/// Reliable (Default : NO)
@property (nonatomic) BOOL reliable;
/// Serialization (Default : MP_SERIALIZATION_BINARY)
@property (nonatomic) MultiPartySerializationEnum serialization;
/// Media constraints (Default : Default values)
@property (nonatomic, copy) SKWMediaConstraints* constraints;
/// Server polling (Default : YES)
@property (nonatomic) BOOL polling;
/// Server polling interval (msec) (Default : 3000)
@property (nonatomic) NSUInteger polling_interval;
/// Auto reconnecting at polling (Default : NO)
@property (nonatomic) BOOL polling_autoreconnect;
/// Outout debug level (Default : MP_DEBUG_LEVEL_NO_LOGS)
@property (nonatomic) MultiPartyDebugLevelEnum debug;
/// location.host (Web browser property)
@property (nonatomic) NSString* locationHost;
/// location.path (Web browser property)
@property (nonatomic) NSString* locationPath;
/// Peer server host (Default : io.skyway)
@property (nonatomic) NSString* host;
/// Peer server port number (Default : 443)
@property (nonatomic) NSUInteger port;
/// Using TLS vs Peer server (Default : YES)
@property (nonatomic) BOOL secure;
/// ICE servers (NSArray[SKWIceConfig,...] ) (Default : Empty array == [stun:stun.skyway.io:3478])
@property (nonatomic) NSArray* config;
/// Using SkyWay TURN server (Default : YES)
@property (nonatomic) BOOL useSkyWayTurn;
/// It tries to use hardware codec H.264 (iOS 8.0 later) (Default : YES)
@property (nonatomic) BOOL useH264;

@end
