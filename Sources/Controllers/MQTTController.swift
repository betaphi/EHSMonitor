//
//  MQTTController.swift
//  
//
//  Created by Bastian Rössler on 23.10.23.
//

import Foundation
import MQTTNIO

actor MQTTController
{
    private let client: MQTTClient
    
    let prefix: String
    
    public init(
        configuration: Configuration.MQTT
    ) {
        self.prefix = configuration.prefix
        
        let configuration = MQTTConfiguration(
            target: .host(configuration.server, port: configuration.port),
            protocolVersion: .version3_1_1,
            clientId: configuration.clientId,
            clean: true,
            credentials: .init(username: configuration.username, password: configuration.password),
            willMessage: nil,
            reconnectMode: .retry(minimumDelay: .seconds(1), maximumDelay: .seconds(10))
        )
        
        self.client = MQTTClient(
            configuration: configuration,
            eventLoopGroupProvider: .createNew
        )
        
        logger.info("Connecting ...")
        
        client.whenConnected { response in
            logger.info("Connected!")
        }
        
        client.whenConnectionFailure { error in
            logger.error("Connection Failure: \(error)")
        }
        
        client.connect()
    }
    
    public func shutdown() async throws
    {
        try await self.client.disconnect()
    }
    
    func publish(string: String, topic: String, qos: MQTTQoS = .atMostOnce, retain: Bool = false) async throws
    {
        guard self.client.isConnected else { throw MQTTPublishError.notConnected }
        
        try await self.client.publish(.init(string), to: self.prefix + "/" + topic, qos: qos, retain: retain)
    }
    
    
    /// Publish UTF8 Data encoded String
    /// - Parameters:
    ///   - data: Will be converted to String before publishing
    ///   - topic: MQTT Topic
    ///   - qos: MQTT QoS
    ///   - retain: MQTT Message Retain flag
    func publish(data: Data, topic: String, qos: MQTTQoS, retain: Bool) async throws
    {
        guard self.client.isConnected else { throw MQTTPublishError.notConnected }

        guard let string = String(data: data, encoding: .utf8) else { throw MQTTPublishError.dataDoesNotConvertToString }
        
        try await self.publish(string: string, topic: topic, qos: qos, retain: retain)
    }
    
    enum MQTTPublishError: Error
    {
        case dataDoesNotConvertToString
        case notConnected
    }
}
