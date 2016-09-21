//
//  CallbackOperation.h
//  MultiParty
//

#import <Foundation/Foundation.h>

#import "MultiParty+Internal.h"

@interface CallbackOperation : NSOperation

/**
 Set parent multiparty object
 @param multiparty MultiParty object
 */
- (void)setMultiParty:(MultiParty *)multiparty;

/**
 Set event type
 @param event Event type
 */
- (void)setEventType:(MultiPartyEventEnum)event;

/**
 Set callback parameter dictionary
 @param dictionary Parameter dictonary
 */
- (void)setCallbackParam:(NSDictionary *)dictionary;

/**
 Set callback block
 @param block Callback block
 */
- (void)setCallbackBlock:(void (^)(NSDictionary *))block;

@end
