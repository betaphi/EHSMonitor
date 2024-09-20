//
//  NASAController+DiscoveredUnits.swift
//
//
//  Created by Bastian Rössler on 17.03.24.
//

import Foundation
import NASAKit

extension Set where Element == NASAController.DiscoveredUnit
{
    func findUnit(class aClass: NASAKit.Address.Class) throws -> NASAController.DiscoveredUnit
    {
        guard let unit = self.first(where: { $0.address.class == aClass }) else {
            throw UnitNotFoundError()
        }
        
        return unit
    }
}

struct UnitNotFoundError: Error { }
