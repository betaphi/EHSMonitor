//
//  AsyncSequence+wait.swift
//
//
//  Created by Bastian Rössler on 13.12.23.
//

import Foundation

extension AsyncSequence where Element: Equatable
{
    public func waitFor(value: Element) async throws
    {
        for try await currentValue in self
        {
            if currentValue == value
            {
                return
            }
        }
        
        try Task.checkCancellation()
        throw AsyncSequenceFinishedWhileWaiting()
    }
    
    public func waitFor(value: Element, timeout: TimeInterval) async throws
    {
        let waitTask = Task {
            try await self.waitFor(value: value)
            try Task.checkCancellation()
        }
        
        let timeoutTask = Task {
            try await Task.sleep(seconds: timeout)
            waitTask.cancel()
        }
        
        try await waitTask.value
        timeoutTask.cancel()
    }
}

public struct AsyncSequenceFinishedWhileWaiting: Error { }
