//
//  MQTTController.swift
//  
//
//  Created by Bastian Rössler on 23.10.23.
//

import Foundation
import MQTTNIO


@MainActor
final class MQTTController
{
    
    private var client: MQTTClient {
        didSet {
            self.connected = false
            self.subscribed = false
        }
    }
    
    public private(set) var connected: Bool = false
    public private(set) var subscribed: Bool = false
    
    let prefix: String
    
    static private let reconnectTime: TimeInterval = 30
    
    init(
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
            reconnectMode: .none
        )
        
        self.client = MQTTClient(
            configuration: configuration,
            eventLoopGroupProvider: .createNew
        )
        
        self.configureClient(self.client)
        
        self.connect()
    }
    
    private func generateId() -> Int32
    {
        if self.previousId == Int32.max
        {
            self.previousId = -1
        }
        self.previousId += 1
        return self.previousId
    }
    private var previousId: Int32 = -1
    
    private func configureClient(_ client: MQTTClient)
    {
        client.whenConnected { [weak self] response in
            DispatchQueue.main.async { [weak self] in
                self?.connected = true
                logger.info("Connected!")
            }
        }
        
        client.whenDisconnected { [weak self] reason in
            DispatchQueue.main.async { [weak self] in
                self?.connected = false
                logger.info("Disconnected: \(reason)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.reconnectTime) { [weak self] in
                    self?.connect()
                }
            }
        }
        
        client.whenConnectionFailure { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                self?.connected = false
                logger.error("ConnectionFailure: \(error)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.reconnectTime) { [weak self] in
                    self?.connect()
                }
            }
        }
    }
    
    private var incomingMessageTask: Task<Void, Never>?
    
    private var connectTask: Task<Void, Error>?
    
    public func connect()
    {
        self.connectTask = Task { [weak self] in
            guard let self = self else { return }
            
            while true
            {
                do {
                    logger.info("Connecting ...")
                    try await self.client.connect()
                    return
                } catch {
                    logger.error("Connect: \(error)")
                }
                
                try await Task.sleep(seconds: Self.reconnectTime)
            }
        }
    }
    
    
    private var subscribeTask: Task<Void, Error>?
    
    func shutdown() async throws
    {
        self.connectTask = nil
        
        self.client.whenDisconnected { reason in
            return
        }
        
        
        try await self.client.disconnect()
    }
    
    func publish(string: String, topic: String, qos: MQTTQoS = .atMostOnce, retain: Bool = false) async throws
    {
        guard self.connected else { throw MQTTPublishError.notConnected }
        
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
        guard self.connected else { throw MQTTPublishError.notConnected }

        guard let string = String(data: data, encoding: .utf8) else { throw MQTTPublishError.dataDoesNotConvertToString }
        
        try await self.publish(string: string, topic: topic, qos: qos, retain: retain)
    }
    
    enum MQTTPublishError: Error
    {
        case dataDoesNotConvertToString
        case notConnected
    }
}
