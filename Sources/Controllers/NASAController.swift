//
//  NASAController.swift
//
//
//  Created by Bastian Rössler on 05.12.23.
//

import Foundation
import NASAKit
import Collections
import AsyncAlgorithms

actor NASAController
{
    /// The amount of time to wait from the last byte read to writing bytes
    private static let readToWriteDelay: TimeInterval = 0.05 // 50ms
    
    /// The maximum amount of bytes to read at once
    private static let maximumReadSize: Int = 256
    
    private let device: String
    private let writeRawDataPath: String?
    private let enableDebugLogging: Bool
    
    private let port: SerialPort
    
    private var readWriteTask: Task<Void, Error>?
    private var autoDiscoveryTask: Task<Void, Error>?
    
    private let nasaDecoder = NASADecoder(enableDebugLogging: false)
    
    let packets = AsyncChannel<Packet>()
    
    /// The date when bytes were last read.
    /// Used to orchestrate a delay between receiving and sending bytes.
    private var previousByteRead: Date = .now
    
    private struct Write
    {
        var packet: Packet
        var bytes: [UInt8]
    }
    
    private var writeBuffer: Deque<Write> = []
    
    public struct DiscoveredUnit: Hashable
    {
        var address: NASAKit.Address
    }
    
    /// The set of discovered units
    public private(set) var discoveredUnits: Set<DiscoveredUnit> = []
    
    private func discover(address: NASAKit.Address)
    {
        let (inserted, object) = self.discoveredUnits.insert(.init(address: address))
        
        if inserted
        {
            logger.info("Discovered \(object)")
        }
    }

    init(
        device: String,
        writeRawDataPath: String?,
        enableDebugLogging: Bool
    ) async throws {
        self.device = device
        self.writeRawDataPath = writeRawDataPath
        self.enableDebugLogging = enableDebugLogging
        
        logger.info("Initializing NASA at \(device) with debugLogging: \(enableDebugLogging)")
        
        self.port = .init(path: device)
        
        try await self.start()
    }
    
    deinit {
        self.readWriteTask?.cancel()
        self.autoDiscoveryTask?.cancel()
    }
    
    /// Start reading and writing the Serial port
    private func start() async throws
    {
        try self.port.openPort(toReceive: true, andTransmit: true)
        
        self.port.setSettings(
            receiveRate: .baud9600,
            transmitRate: .baud9600,
            minimumBytesToRead: 0,
            timeout: 0,
            parityType: .even,
            sendTwoStopBits: false,
            dataBitsSize: .bits8,
            useHardwareFlowControl: false,
            useSoftwareFlowControl: false,
            processOutput: false
        )
        
        self.readWriteTask = Task.detached { [weak self] in
            while Task.isCancelled == false
            {
                guard let self else { return }
                try await self.readWrite()
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            
            await self?.port.closePort()
        }
        
        self.autoDiscoveryTask = Task.detached { [weak self, nasaDecoder] in
            for await packet in await nasaDecoder.packets
            {
                guard let self else { return }
                await self.discover(address: packet.source)
                await self.packets.send(packet)
            }
        }
    }
    
    /// Internal function that is executed regularly in order to read and/or write bytes from and to the Serial port
    private func readWrite() async throws
    {
        if let bytes = try await self.read()
        {
            //self.log("Received \(bytes.count) bytes", level: .trace)
            
            let date = Date()
            await self.nasaDecoder.decodeBytes(bytes, date: date)
            self.previousByteRead = date
            
            Self.writeToFile(data: Data(bytes), date: date, path: self.writeRawDataPath)
            
            return
        }

        // did not read bytes -> maybe write
        guard Date().timeIntervalSince(self.previousByteRead) >= Self.readToWriteDelay else { return }
        guard let write = self.writeBuffer.popFirst() else { return }
        
        let _ = try self.port.writeData(.init(write.bytes))
        
        Self.writeToFile(data: Data(write.bytes), date: .now, path: self.writeRawDataPath)
        
        logger.trace("didWrite: \(write.packet.id)")
    }
    
    private func read() async throws -> [UInt8]?
    {
        let bytes = try self.port.readData(ofLength: Self.maximumReadSize)
        guard bytes.isEmpty == false else { return nil }
        
        return [UInt8](bytes)
    }
    
    /// Write packet to the Serial Port
    /// - Parameter packet: The Packet to write
    public func write(packet: Packet) async throws
    {
        let data = try packet.encode()
        let write = Write(packet: packet, bytes: data)
        self.writeBuffer.append(write)
        
        logger.trace("didQueue: \(write.packet.id)")
    }

    // MARK: - Static Helper Functions
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private static func writeToFile(data: Data, date: Date, path: String?)
    {
        guard let path else { return }
        
        let string = "[" + Self.formatter.string(from: Date()) + "] " + data.toHexString() + "\n"
        
        let ff = fopen(path, "a+")
        fputs(string, ff)
        fclose(ff)
    }
}

