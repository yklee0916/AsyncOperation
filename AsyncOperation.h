//
//  AsyncOperation.h
//
//  Created by younggi.lee on 11/07/2018.
//  Copyright © 2018 younggi.lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AsyncOperationProtocol <NSObject>

// TODO this method will be excueted when it added on queue although waiting previous operations.
- (void)whenQueued;

// TODO this method will be run when it's turn in queue, and should called -(void)finish method when it done.
- (void)mainTask;

@end

@interface AsyncOperation : NSObject <AsyncOperationProtocol>

- (BOOL)isRunning;
- (BOOL)isCancelled;
- (void)cancel;
- (void)finish;

@end

@interface AsyncOperationQueue : NSObject

@property (readonly) NSUInteger operationCount;

- (void)addOperation:(AsyncOperation *)operation;
- (void)cancelAllOperations;

@end
