//
//  MultiParty.h
//  MultiParty
//

#import <Foundation/Foundation.h>


#import "MultiPartyOption.h"

#import <SkyWay/SKWPeerError.h>


/**
 MultiParty event type
 */
typedef NS_ENUM(NSUInteger, MultiPartyEventEnum)
{
	/**
	 Opened multiparty.
	 @{ peer-id : (Peer Id) }
	 */
	MULTIPARTY_EVENT_OPEN,
	
	/**
	 Open own media stream.
	 @{ src : (SKWMediaStream) , id : (ID) }
	 */
	MULTIPARTY_EVENT_MY_MS,
	
	/**
	 Open remote media stream.
	 @{ src : (SKWMediaStream) , id : (ID) , reconnect : (BOOL) }
	 */
	MULTIPARTY_EVENT_PEER_MS,
	
	/**
	 Close remote media stream.
	 @{ id : (ID) }
	 */
	MULTIPARTY_EVENT_MS_CLOSE,
	
	/**
	 Open remote screen cast stream.
	 @{ src : (SKWMediaStream) , id : (ID) , reconnect : (BOOL) }
	 */
	MULTIPARTY_EVENT_PEER_SS,
	
	/**
	 Close remote screen cast stream.
	 @{ id : (ID) }
	 */
	MULTIPARTY_EVENT_SS_CLOSE,

	/**
	 Open remote data channel.
	 @{ id : (ID) }
	 */
	MULTIPARTY_EVENT_DC_OPEN,
	
	/**
	 Received message
	 @{ id : (ID) , data : (NSObject) }
	 */
	MULTIPARTY_EVENT_MESSAGE,
	
	/**
	 Close remote data channel.
	 @{ id : (ID) }
	 */
	MULTIPARTY_EVENT_DC_CLOSE,
	
	/**
	 Rise error.
	 @{ error : (MultiPartyError) , peerError : (SKWPeerError) }
	 */
	MULTIPARTY_EVENT_ERROR,
};


@interface MultiParty : NSObject


@property (nonatomic, readonly) BOOL opened;
@property (nonatomic) BOOL reconnecting;


/**
 SKWMultiParty object initialize.
 @param option Initialize option.
 @return Object.
 */
- (instancetype)initWithOption:(MultiPartyOption *)option;

/**
 Start multi party.
 */
- (void)start;

/**
 Set event callbacks
 */
- (void)on:(MultiPartyEventEnum)event callback:(void (^)(NSDictionary *))callback;

/**
 Mute own video and audio.
 @param video NO:unmute video YES:mute video
 @param audio NO:unmute audio YES:mute audio
 */
- (void)muteVideo:(BOOL)video audio:(BOOL)audio;

/**
 Remove remote peer connection.
 @param peerId Remote peer id
 @return Result code.
 */
- (BOOL)removePeer:(NSString *)peerId;

/**
 Send data to all remotes.
 @param data Send data.
 @return Result code.
 */
- (BOOL)send:(NSObject *)data;

/**
 Close all connections and destroy peer.
 */
- (void)close;

/**
 Listing all peers.
 @param callback Listing callback.
 */
- (BOOL)listAllPeers:(void (^)(NSArray *))callback;

/**
 Reconnecting remote
 */
- (void)reconnectVideo:(BOOL)video screen:(BOOL)screen data:(BOOL)data;

@end
