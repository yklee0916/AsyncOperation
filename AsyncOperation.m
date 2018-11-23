//
//  AsyncOperation.m
//
//  Created by younggi.lee on 11/07/2018.
//  Copyright © 2018 younggi.lee. All rights reserved.
//

#import "AsyncOperation.h"

typedef NS_ENUM(NSInteger, AsyncOperationState) {
    AsyncOperationStateReady = 0,
    AsyncOperationStateExcuting,
    AsyncOperationStateCanceled,
    AsyncOperationStateFinished
};

@protocol AsyncOperationDelegate <NSObject>

- (void)operationDidFinish:(AsyncOperation *)operation;

@end

@interface AsyncOperation ()

@property (assign, nonatomic) AsyncOperationState state;
@property (weak, nonatomic) id<AsyncOperationDelegate> delegate;

@end


@implementation AsyncOperation

- (BOOL)isRunning {
    return self.state == AsyncOperationStateExcuting;
}

- (BOOL)isCancelled {
    return self.state == AsyncOperationStateCanceled;
}

- (void)start {
    if([self isCancelled]) {
        [self finish];
        return ;
    }
    self.state = AsyncOperationStateExcuting;
    [self mainTask];
}

- (void)cancel {
    self.state = AsyncOperationStateCanceled;
}

- (void)finish {
    self.state = AsyncOperationStateFinished;
    
    if(nil != self.delegate && [self.delegate respondsToSelector:@selector(operationDidFinish:)]){
        [self.delegate operationDidFinish:self];
    }
}

# pragma mark - <AsyncOperationProtocol>

// TODO this method will be excueted when it added although waiting previous operations
- (void)whenQueued {
}

// TODO process and call [finish] method when it done
- (void)mainTask {
    [self finish];
}

@end

@interface AsyncOperationQueue () <AsyncOperationDelegate>

@property (strong) NSMutableArray <AsyncOperation *> *operations;
@property (strong, nonatomic) dispatch_queue_t operationThread;

@end

@implementation AsyncOperationQueue

- (instancetype)init {
    if(self = [super init]) {
        self.operations = [NSMutableArray array];
        self.operationThread = dispatch_queue_create([@"AsyncOperationQueueThread" UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSUInteger)operationCount {
    return self.operations.count;
}

- (void)addOperation:(AsyncOperation *)operation {
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async(self.operationThread, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        BOOL shouldStartImmediately = (strongSelf.operationCount == 0);
        
        [strongSelf.operations addObject:operation];
        [operation whenQueued];
        
        if(shouldStartImmediately) [strongSelf start];
    });
}

- (void)cancelAllOperations {
    
    AsyncOperation *firstOperation = self.operations.firstObject;
    BOOL shouldFinishFirstObject = firstOperation.state == AsyncOperationStateExcuting;
    
    for(AsyncOperation *operation in self.operations) { [operation cancel]; }
    
    if(shouldFinishFirstObject) [firstOperation finish];
}

- (void)start {
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async(self.operationThread, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        AsyncOperation *operation = strongSelf.operations.firstObject;
        if(nil != operation) {
            operation.delegate = strongSelf;
            [operation start];
        }
    });
}

# pragma mark - <AsyncOperationDelegate>

- (void)operationDidFinish:(AsyncOperation *)operation {
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async(self.operationThread, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        if(strongSelf.operationCount == 0) return ;
        
        if(nil != operation && [strongSelf.operations indexOfObject:operation] != NSNotFound) {
            [strongSelf.operations removeObject:operation];
        }
    });
    [self start];
}

@end
