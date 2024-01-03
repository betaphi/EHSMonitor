//
//  CancellationState.swift
//
//
//  Created by Bastian Rössler on 09.12.23.
//

import Foundation

/// Thread safe cancellation state
public final class CancellationState: @unchecked Sendable
{
    private let semaphore = DispatchSemaphore(value: 1)
    
    public var isCancelled: Bool {
        get {
            self.semaphore.wait()
            defer {
                self.semaphore.signal()
            }
            return self._isCancelled
        }
    }
    
    private var _isCancelled: Bool = false
    
    public func cancel() {
        self.semaphore.wait()
        defer {
            self.semaphore.signal()
        }
        self._isCancelled = true
    }
    
    public init() { }
}
