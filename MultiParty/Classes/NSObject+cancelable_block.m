//
//  NSObject+cancelable_block.m
//  SKWPeer
//

#import "NSObject+cancelable_block.h"

@implementation NSObject (cancelable_block)


- (dispatch_cancelable_block_t)dispatch_after_delay:(NSInteger)sec block:(dispatch_block_t)block
{
	if ((nil == block) || (0 == sec))
	{
		return nil;
	}
	
	__block dispatch_cancelable_block_t blkCancelable = nil;
	__block dispatch_block_t blkOriginal = [block copy];
	
	dispatch_cancelable_block_t delayBlock = ^(BOOL cancel) {
		if ((NO == cancel) && (nil != blkOriginal))
		{
			dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
			dispatch_async(queue, blkOriginal);
		}
		
		blkOriginal = nil;
		blkCancelable = nil;
	};

	blkCancelable = [delayBlock copy];
	
	dispatch_time_t tm = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sec * NSEC_PER_SEC));
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_after(tm, queue, ^(void) {
		if (nil != blkCancelable)
		{
			blkCancelable(NO);
		}
	});

	block = nil;
	
	return blkCancelable;
}

- (void)cancel_after_delay:(dispatch_cancelable_block_t)cancelableBlock
{
	if (nil == cancelableBlock)
	{
		return;
	}
	
	cancelableBlock(YES);
}

@end
