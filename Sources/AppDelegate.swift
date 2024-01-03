//
//  AppDelegate.swift
//
//
//  Created by Bastian Rössler on 03.01.24.
//

import Foundation

@MainActor
final class AppDelegate: BRApplicationDelegate
{
    let mqttController: MQTTController
    let ehsContorller: EHSController
    
    
    init(configuration: Configuration)
    {
        self.mqttController = .init(
            configuration: configuration.mqtt
        )
        
        self.ehsContorller = .init(
            configuration: configuration.ehs,
            mqttController: self.mqttController
        )
    }
}
