//
//  CancelOnDeinitTask.swift
//
//
//  Created by Bastian Rössler on 08.12.23.
//

import Foundation

class CancelOnDeinitTask<Success>: Hashable, Equatable
{
    func hash(into hasher: inout Hasher)
    {
        self.task.hash(into: &hasher)
    }
    
    static func == (lhs: CancelOnDeinitTask<Success>, rhs: CancelOnDeinitTask<Success>) -> Bool
    {
        lhs.task == rhs.task
    }
    
    private let task: Task<Success, Error>
    
    @discardableResult public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self.task = Task<Success, Error>(priority: priority, operation: operation)
    }
    
    func cancel()
    {
        self.task.cancel()
    }
    
    var isCancelled: Bool
    {
        self.task.isCancelled
    }
    
    deinit {
        self.task.cancel()
    }
}
