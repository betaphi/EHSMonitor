//
//  Configuration.swift
//
//
//  Created by Bastian Rössler on 03.01.24.
//

import Foundation

struct Configuration: Codable
{
    struct MQTT: Codable
    {
        /// MQTT Subject prefex for sending and receiving messages
        var prefix: String
        
        var server: String
        var port: Int
        var clientId: String
        var username: String
        var password: String
    }
    
    struct EHS: Codable
    {
        /// Serial device for Reading NASA communication
        var nasaDevice: String
        /// Optional: Path to write RAW NASA Data for debugging
        var rawNasaWritePath: String?
    }
    
    let mqtt: MQTT
    let ehs: EHS
    
    init(path: String) throws
    {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        
        self = try JSONDecoder().decode(Configuration.self, from: data)
    }
}
