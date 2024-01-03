// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import ConsoleKitTerminal
import Logging

@main
struct EHSMonitor: ParsableCommand 
{
    @Option(name: .shortAndLong, help: "Specify the path to the configuration file") var config: String = "EHSMonitorConfig.json"
    
    
    @MainActor
    mutating func run() throws
    {
        LoggingSystem.bootstrap(
            fragment: defaultLoggerFragment(),
            console: Terminal()
        )
        
        let configuration = try Configuration(path: config)
        
        BRApplication().delegate = AppDelegate(configuration: configuration)
    }
}
