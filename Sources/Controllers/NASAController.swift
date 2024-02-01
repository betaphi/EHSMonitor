//
//  NASAController.swift
//
//
//  Created by Bastian Rössler on 05.12.23.
//

import Foundation
import NASAKit


final class NASAController: @unchecked Sendable
{
    /// The amount of time to wait from the last byte read to writing bytes
    private static let readToWriteDelay: TimeInterval = 0.05 // 50ms
    
    /// The maximum amount of bytes to read at once
    private static let maximumReadSize: Int = 256
    
    private let device: String
    private let writeRawDataPath: String?
    private let enableDebugLogging: Bool
    
    private let port: SerialPort
    
    /// The queue that is used to access the serial port
    private let serialQueue = DispatchQueue(label: "NASASerial")
    
    /// The queue that is used to write packets
    private let writeQueue = DispatchQueue(label: "NASAWrite")
    
    init(
        device: String,
        writeRawDataPath: String?,
        enableDebugLogging: Bool
    ) throws {
        self.device = device
        self.writeRawDataPath = writeRawDataPath
        self.enableDebugLogging = enableDebugLogging
        
        logger.info("Initializing NASA at \(device) with debugLogging: \(enableDebugLogging)")
        
        self.port = SerialPort(path: device)
        
        try self.port.openPort(toReceive: true, andTransmit: true)
        
        // configure port
        self.port.setSettings(
            receiveRate: .baud9600,
            transmitRate: .baud9600,
            minimumBytesToRead: 0,
            timeout: 0,
            parityType: .none,
            sendTwoStopBits: false,
            dataBitsSize: .bits8,
            useHardwareFlowControl: true,
            useSoftwareFlowControl: false,
            processOutput: false
        )
        
        self.addReadToQueue()
    }
    
    /// The date when bytes were last read.
    /// Used to orchestrate a delay between receiving and sending bytes.
    private var previousByteRead: Date = .now
    
    
    private func addReadToQueue()
    {
        self.serialQueue.async { [weak self] in
            self?.read()
        }
    }
    
    private func read()
    {
        defer {
            // loop
            self.addReadToQueue()
        }
        
        guard let bytes = try? self.port.readData(ofLength: Self.maximumReadSize),
              bytes.isEmpty == false else
        {
            // read failed or no bytes to read
            return
        }
        
        // we have received bytes
        self.previousByteRead = Date()
        
        self.byteStreamContinuation?.yield([UInt8](bytes))
    }
    
    private var byteStreamContinuation: AsyncStream<[UInt8]>.Continuation?
    
    public func write(packet: Packet) async throws
    {
        let data = try packet.encode()
        
        let _: Void = try await withCheckedThrowingContinuation { [weak self] continuation in
            
            guard let self = self else {
                continuation.resume(throwing: CancellationError())
                return
            }
            
            // Add the data to the write queue
            self.writeQueue.async { [weak self] in
                
                // check if NASAController is already deinited
                guard let self = self else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                // use to make sure to only write once
                var written = false
                
                // try to write as long as the write was not performed
                while written == false
                {
                    // Perform write on the serialQueue
                    self.serialQueue.sync { [weak self] in
                        
                        // check if NASAController is already deinited
                        guard let self = self else {
                            // end the while loop
                            written = true
                            
                            // notify the continuation
                            continuation.resume(throwing: CancellationError())
                            
                            return
                        }
                        
                        do {
                            // check for read to write delay
                            guard Date().timeIntervalSince(self.previousByteRead) > Self.readToWriteDelay else {
                                // have to wait some more
                                // as written is false, the loop will make sure the next
                                // write attempt is scheduled
                                return
                            }
                            
                            // the delay since the last read has passed
                            // => this is the final write attempt
                            // Either it will succeed or fail but we will not retry
                            defer {
                                written = true
                            }
                            
                            // write the data
                            let _ = try self.port.writeData(.init(data))
                            
                            // notify the continuation
                            continuation.resume()
                        } catch {
                            
                            // write failed, notify the continuation
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    var packets: AsyncStream<Packet>
    {
        let byteStream = AsyncStream<[UInt8]> { [weak self] continuation in
            
            self?.byteStreamContinuation = continuation
            
            continuation.onTermination = { [weak self] _ in
                self?.byteStreamContinuation = nil
            }
        }
        
        return AsyncStream<Packet> { continuation in
            
            let nasaDecoder = NASADecoder(enableDebugLogging: enableDebugLogging)
            
            let packetTask = Task {
                for await packet in await nasaDecoder.packets
                {
                    continuation.yield(packet)
                }
                
                continuation.finish()
            }
            
            let decodeTask = Task {
                for await bytes in byteStream
                {
                    let currentDate = Date()
                    Self.writeToFile(data: Data(bytes), date: currentDate, path: writeRawDataPath)
                    await nasaDecoder.decodeBytes(bytes, date: currentDate)
                }
            }
            
            continuation.onTermination = { _ in
                decodeTask.cancel()
                packetTask.cancel()
            }
        }
    }
    

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

