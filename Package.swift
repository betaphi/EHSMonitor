// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EHSMonitor",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/sroebert/mqtt-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/betaphi/NASAKit.git", branch: "main"),
        .package(url: "https://github.com/christophhagen/SwiftSerial.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/console-kit", from: "4.0.0"),
        .package(url: "https://github.com/reddavis/Asynchrone.git", from: "0.21.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.1.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "EHSMonitor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MQTTNIO", package: "mqtt-nio", condition: .none),
                .product(name: "NASAKit", package: "NASAKit"),
                .product(name: "SwiftSerial", package: "SwiftSerial"),
                .product(name: "ConsoleKitTerminal", package: "console-kit"),
                .product(name: "Asynchrone", package: "Asynchrone"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
    ]
)
