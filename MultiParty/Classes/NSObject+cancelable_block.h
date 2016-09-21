//
//  NSObject+cancelable_block.h
//  SKWPeer
//

#import <Foundation/Foundation.h>

typedef void(^dispatch_cancelable_block_t)(BOOL cancel);

@interface NSObject (cancelable_block)

- (dispatch_cancelable_block_t)dispatch_after_delay:(NSInteger)sec block:(dispatch_block_t)block;

- (void)cancel_after_delay:(dispatch_cancelable_block_t)block;

@end
