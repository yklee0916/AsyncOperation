//
//  AsyncOperation.swift
//  test2
//
//  Created by SKT1110984 on 23/11/2018.
//  Copyright © 2018 SK Telecom. All rights reserved.
//

import Foundation

fileprivate protocol AsyncOperationDelegate: class {
    func didFinish(operation: AsyncOperation);
}

internal enum AsyncOperationState: Int32 {
    case ready
    case executing
    case cancelled
    case finished
}

public class AsyncOperation: NSObject {
    
    fileprivate var state: AsyncOperationState = .ready
    fileprivate weak var delegate: AsyncOperationDelegate?
    
    var running: Bool {
        return state == .executing
    }
    
    var cancelled: Bool {
        return state == .cancelled
    }
    
    public func finish() {
        state = .finished
        delegate?.didFinish(operation: self)
    }
    
    fileprivate func start() {
        if cancelled {
            finish()
            return
        }
        state = .executing
        mainTask()
    }
    
    fileprivate func cancel() {
        state = .cancelled
    }
}

extension AsyncOperation {
    
    // TODO this method will be excueted when it added on queue although waiting previous operations.
    @objc internal func whenQueued() {
    }
    
    // TODO this method will be run when it's turn in queue, and should called -(void)finish method when it done.
    @objc internal func mainTask() {
        self.finish()
    }
}

public class AsyncOperationQueue: NSObject {
    
    fileprivate var operations = NSMutableArray.init()
    fileprivate var operationThread = DispatchQueue(label: "AsyncOperationQueue")
    
    var operationCount: Int {
        return operations.count
    }
    
    public override init() {
    }
    
    public func add(operation: AsyncOperation) {
        operationThread.async {
            let shouldStartImmediately = self.operationCount == 0
            
            self.operations.add(operation)
            operation.whenQueued()
            
            if shouldStartImmediately { self.start() }
        }
    }
    
    public func cancelAll() {
        
        guard let firstOperation = operations.firstObject as? AsyncOperation else { return }
        let shouldFinishFirstObject = firstOperation.state == .executing
        
        for o in operations {
            guard let operation = o as? AsyncOperation else { return }
            operation.cancel()
        }
        if shouldFinishFirstObject { firstOperation.finish() }
    }
    
    private func start() {
        operationThread.async {
            guard let operation = self.operations.firstObject as? AsyncOperation else { return }
            operation.delegate = self
            operation.start()
        }
    }
}

extension AsyncOperationQueue: AsyncOperationDelegate {
    
    fileprivate func didFinish(operation: AsyncOperation) {
        operationThread.async {
            if self.operationCount == 0, self.operations.index(of: operation) == NSNotFound { return }
            self.operations.remove(operation)
            self.start()
        }
    }
}


