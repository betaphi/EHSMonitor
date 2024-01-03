//
//  ContinuationHolder.swift
//
//
//  Created by Bastian Rössler on 09.12.23.
//

import Foundation

class ContinuationHolder<Value>
{
    var continuation: AsyncStream<Value>.Continuation?
}
