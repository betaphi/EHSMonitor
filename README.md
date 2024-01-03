# EHSMonitor

## About

This application uses the NASA protocol to monitor a Samsung EHS Mono HT Quiet unit and publish its values via MQTT. See `EHSController.swift` for published MQTT topics.

## How to run

1. Install a Swift environment. For example via docker: https://hub.docker.com/_/swift/
2. Clone this repository.
3. Run `swift build`
4. Copy and edit the `ExampleConfiguration.json` to your liking.

By default the build command will build the executable in a debug configuration. As this is an early development release, this is fine. The executable will be located at `./.build/debug/EHSMonitor` inside your local copy of the repository.

Run the executlabe via `./.build/debug/EHSMonitor --config $PathToConfigurationFile`

