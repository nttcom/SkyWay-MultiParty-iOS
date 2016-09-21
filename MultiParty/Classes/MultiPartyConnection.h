//
//  MultiPartyConnection.h
//  MultiParty
//

#import <Foundation/Foundation.h>

#import "MultiParty+Internal.h"

#import <SkyWay/SKWDataConnection.h>
#import <SkyWay/SKWMediaConnection.h>

@interface MultiPartyConnection : NSObject

@property (nonatomic) MultiParty* multiparty;
@property (nonatomic) NSString* peer;
@property (nonatomic) NSMutableArray* medias;
@property (nonatomic) NSMutableArray* datas;

/**
 Close all connections
 */
- (void)close;

/**
 Add media connection
 @param media Media connection
 */
- (void)addMediaConnection:(SKWMediaConnection *)media;
/**
 Remove media connection
 @param media Media connection
 */
- (void)removeMediaConnection:(SKWMediaConnection *)media;

/**
 Add data connection
 @param data Data connection
 */
- (void)addDataConnection:(SKWDataConnection *)data;
/**
 Remove data connection
 @param data Data connection
 */
- (void)removeDataConnection:(SKWDataConnection *)data;

@end
