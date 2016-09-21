//
//  ListingPeerOperation.h
//  MultiParty
//

#import <Foundation/Foundation.h>

#import <SkyWay/SKWPeer.h>

@interface ListingPeerOperation : NSOperation

/**
 Set Peer
 @param peer
 */
- (void)setPeer:(SKWPeer *)peer;

/**
 Set own peer ID
 @param peerId
 */
- (void)setOwnPeerId:(NSString *)peerId;

/**
 Set room ID
 @param roomId
 */
- (void)setRoomId:(NSString *)roomId;

/**
 Set listing result block
 @param block
 */
- (void)setListingResultBlock:(void (^)(NSArray *))block;

@end
