//
//  Measurement.swift
//
//
//  Created by Bastian Rössler on 25.10.23.
//

import Foundation
import MQTTNIO
import Asynchrone

/// Stores a value that will expire over time
/// The value will automatically be `nil`, when expired
@propertyWrapper
public class Measurement<Value> where Value: Equatable
{
    public var wrappedValue: Value? {
        didSet {
            self.continuationHolder.continuation?.yield(self.wrappedValue)
        }
    }
    
    /// The continuation of the AsyncStream that collects the Values
    private let continuationHolder = ContinuationHolder<Value?>()
    
    /// Sahred async sequence that is downstream of the AsyncStream that belongs to the stored continuation
    private let _values: SharedAsyncSequence<AsyncStream<Value?>>
    
    public var values: ChainAsyncSequence<Just<Value?>, SharedAsyncSequence<AsyncStream<Value?>>> {
        return Just(self.wrappedValue)
            .chain(with: self._values)
    }

    public func waitFor(value: Value?) async throws
    {
        try Task.checkCancellation()
        
        guard value != self.wrappedValue else {
            return
        }
        try await self.values.waitFor(value: value)
    }
    
    public func waitFor(value: Value?, timeout: TimeInterval) async throws
    {
        try Task.checkCancellation()
        
        guard value != self.wrappedValue else {
            return
        }
        try await self.values.waitFor(value: value, timeout: timeout)
    }
    
    /// Specifies for how long the value is deemed valid
    public let validity: TimeInterval
    
    /// Task that listens for changes in the value and schedules the expiration
    private var scheduleExpirationTaskTask: CancelOnDeinitTask<Void>?
    
    /// Task that actually expires a value
    private var expirationTask: CancelOnDeinitTask<Void>?
    
    /// Function that schedules the expiration
    private func scheduleExpirationTask()
    {
        self.expirationTask = nil
        
        guard let _ = self.wrappedValue else {
            // no need to expire `nil`
            return
        }
        
        let validity = self.validity
        
        guard validity < .greatestFiniteMagnitude &&
                validity > 0
        else {
            // no need to expire a value in the above cases
            return
        }
        
        self.expirationTask = CancelOnDeinitTask { [weak self] in
            try await Task.sleep(seconds: validity)
            self?.wrappedValue = nil
        }
    }

    public convenience init(
        wrappedValue: Value? = nil,
        validity: TimeInterval = 30
    ) {
        self.init(
            wrappedValue: wrappedValue,
            validity: validity,
            mqtt: nil
        )
    }
    
    internal init(
        wrappedValue: Value? = nil,
        validity: TimeInterval = 30,
        mqtt: MQTTPublishOptions<Value>? = nil
    ) {
        self.validity = validity
        
        let continuationHolder = self.continuationHolder
        
        let valuesStream = AsyncStream<Value?> { continuation in
            
            continuation.onTermination = { _ in
                continuationHolder.continuation = nil
            }
            
            continuationHolder.continuation = continuation
        }
        
        self._values = .init(valuesStream)
        
        
        // MQTT
        self.mqtt = mqtt
        let channel = self.values
        
        self.publishTask = Task {
            guard let mqtt = mqtt else { return }
            
            for try await value in channel.throttle(for: mqtt.throttle, latest: true)
            {
                guard let value else { continue }
                guard let string = mqtt.transform(value) else { continue }
                try? await mqtt.controller.publish(string: string, topic: mqtt.topic, qos: mqtt.qos, retain: mqtt.retain)
            }
        }
        
        // Expiration
        self.scheduleExpirationTaskTask = CancelOnDeinitTask { [weak self] in
            
            guard let values = self?.values else { return }
            
            for try await _ in values
            {
                self?.scheduleExpirationTask()
            }
        }
    }
    
    deinit
    {
        self.continuationHolder.continuation?.finish()
        self.continuationHolder.continuation = nil
    }
    
    // MARK: - MQTT Publishing
    private var publishTask: Task<Void, Error>?
    
    private var mqtt: MQTTPublishOptions<Value>?
    
    public func immediateMQTTPublish(overrideQOS: MQTTQoS? = nil, overrideRetain: Bool? = nil) async throws
    {
        guard let mqtt = self.mqtt else { throw MQTTError.noMQTT }
        guard let value = self.wrappedValue else { throw MQTTError.noValue }
        guard let string = mqtt.transform(value) else { throw MQTTError.transformerDeliveredNil }
        
        try await mqtt.controller.publish(
            string: string,
            topic: mqtt.topic,
            qos: overrideQOS ?? mqtt.qos,
            retain: overrideRetain ?? mqtt.retain
        )
    }
    
    enum MQTTError: Error
    {
        case noMQTT
        case noValue
        case transformerDeliveredNil
    }
}



struct MQTTPublishOptions<Value>
{
    let controller: MQTTController
    let topic: String
    let transform: (Value) -> String?
    let qos: MQTTQoS
    let retain: Bool
    let throttle: TimeInterval = 5
    
    init(
        controller: MQTTController,
        topic: String,
        transform: @escaping (Value) -> String? = {
            "\($0)"
        },
        qos: MQTTQoS = .atMostOnce,
        retain: Bool = false
    ) {
        self.controller = controller
        self.topic = topic
        self.transform = transform
        self.qos = qos
        self.retain = retain
    }
}


#if DEBUG
@MainActor
class SomeController
{
    let value = Measurement<Int>()
}

#endif
