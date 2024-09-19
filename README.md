# EHSMonitor

## About

This application uses the NASA protocol to monitor a Samsung EHS Mono HT Quiet unit and publish its values via MQTT. See `EHSController.swift` for published MQTT topics.

## Hrdware Setup

Connect the Samsung Indoor Unit or Wifi Kit F1/F2 Connectors to an RS485 Adapter.
F1 -> A+
F2 -> B-

more detailed description under [wiki](https://wiki.myehs.eu/wiki/F1/F2_connector)

## Run from Dockerfile
1. Clone this repository
2. Run `docker build -t ehsmonitor EHSMonitor/.`
3. Create an Folder to store the Configuration file `mkdir EHSMonitor_dockervolume`
4. Copy the Sample Configuration file `cp Resources/ExampleConfiguration.json EHSMonitor_dockervolume/Configuration.json`
5. Edit the `Configuration.json` with your favorite editor
6. Run the Docker Container in dettached mode `docker run --device=/dev/ttyUSB0 -v /root/EHSMonitor_dockervolume:/media/persistvol --name ehsmonitor -dt ehsmonitor`
   - `--device=/dev/ttyUSB0` passthrough your USB Device to the container, if your USB rs485 Adapter is on another device, provide here yours
   - `-v /root/EHSMonitor_dockervolume:/media/persistvol` The docker container storage is not persistant, so you need to mount your `EHSMonitor_dockervolume` folder to your container under `media/persistvol` to provide you Configuration file.
   - `--name ehsmonitor` name your container instance, without it, docker will generate an generic one
   - `-dt ehsmonitor` -d = dettached mode (background)
8. Start the EHSMonitor within your docker instance `docker exec -it ehsmonitor .build/debug/EHSMonitor --config /media/persistvol/Configuration.json > /dev/null 2>&1 &`
   - `-it ehsmonitor` your instance name, if you did not provide `--name ehsmonito` on the `docker run` command, type `docker ps` to get the generic name
   - ` > /dev/null 2>&1 &` pipe the output to null so it runs in background.


By default the build command will build the executable in a debug configuration. As this is an early development release, this is fine. The executable will be located at `./.build/debug/EHSMonitor` inside your local copy of the repository.

Run the executlabe via `./.build/debug/EHSMonitor --config $PathToConfigurationFile`

