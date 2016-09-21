//
//  MultiPartyOption+Internal.h
//  MultiParty
//

#import <Foundation/Foundation.h>


#import "MultiPartyOption.h"

#import <SkyWay/SKWPeerOption.h>

@interface MultiPartyOption ()

@property (nonatomic) BOOL use_stream;
@property (nonatomic) SKWPeerOption* peerOption;
@property (nonatomic) NSString* room_name;
@property (nonatomic) NSString*	room_id;

@end
