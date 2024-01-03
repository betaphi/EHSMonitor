//
//  Data+toHexString.swift
//
//
//  Created by Bastian Rössler on 03.01.24.
//

import Foundation

extension Data
{
    func toHexString() -> String
    {
        self.map { String(format: "%02hhx", $0) }.joined()
    }
}
