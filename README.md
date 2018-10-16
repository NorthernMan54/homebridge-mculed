# homebridge-wssensor
Plugin for NodeMCU Based sensors using WebSockets for realtime updates

# Design Concept

* Realtime device communications via WebSockets, and device discovery via mDNS
* Homebridge Plugin creates a websocket server to receive updates from nodemcu devices.
* Plugin advertises websocket server onto network via mDNS
* NodeMCU discovers server by watching for mDNS advertisement
* NodeMCU sends message to plugin containing sensor config
* Plugin creates HK accessory for sensor ( Have ability to alias sensor name in config.json )
* Plugin sends sensor state changes in realtime to plugin via WebSockets
* Default publishing every minute?
* Have sensor support multiple websocket servers?
* Support for Legacy mcuiot mode?
* Support for data logging to mcuiot-logger?

# Supported configurations

* [x] AM312 or HC-SR501 Motion Sensor and BME280 or DHT22 Temperature sensor
* [x] MPU6050 Gyro / Acceleration sensor
* [x] Garage Door monitor / control
* [ ] YL-69 Moisture Sensor / BME-280
* [ ] Standalone BME280 Temperature Sensor

# Supported sensors

* HC-SR501 Motion Sensor Module ( This one generates alot of false positives )
* I used this one, https://www.aliexpress.com/item/Mini-IR-Pyroelectric-Infrared-PIR-Motion-Human-Sensor-Automatic-Detector-Module-high-reliability-12mm-x-25mm/32749737125.html?spm=a2g0s.9042311.0.0.6ec74c4dwcSLq4

# Backlog - Plugin

* [x] Homebridge Plugin creates a websocket server to receive updates from nodemcu devices.
* [x] Plugin advertises websocket server onto network via mDNS
* [x] Plugin creates HK accessory for sensor ( Have ability to alias sensor name in config.json )
* [x] Plugin sends sensor state changes in realtime to HomeKit
* [x] Plugin sets Low Battery when sensor has an error
* [x] Plugin sets "No Response" when device is no longer responds on the network
* [x] Default publishing every minute?
* [ ] Remove redundant code from plugin
* [X] Support fakeGato
* [X] Switch to event based model
* [ ] Support for Legacy mcuiot mode?
* [ ] Support for data logging to mcuiot-logger?

# Backlog - NodeMCU

* [x] NodeMCU discovers server by watching for mDNS advertisement
* [x] NodeMCU sends message to plugin containing sensor config
* [x] Sensor sends state changes in realtime to plugin via WebSockets
* [x] Allow sensor to warm up before publishing, I believe I read 1 minute
* [x] Have sensor send not available status during warm up period -- Not required
* [x] Support for OTA Updates
* [ ] Have sensor support multiple websocket servers
* [ ] Support for Legacy mcuiot mode
* [x] Stop committing passwords to github!! -- Done

# Installation - homebridge-wssensor

```
sudo npm install -g homebridge-wssensor
```

# Configuration - homebridge-wssensor

```
{
  "platform": "wssensor",
  "name": "wssensor",
  "port": 4050,
  "refresh": "60",
  "storage": "fs",
  "leak": "10",
  "aliases": {
    "NODE-2BA0FF": "Porch Motion"
  }
}
```

* `port`      - Listener port for sensor to send data to
* `refresh`   - Polling frequency, defaults to 60 seconds
* `storage`   - Storage of chart graphing data for history graphing, either fs or googleDrive, defaults to fs
* `leak`      - Leak sensor alarm trigger percentage, defaults to 10%
* `service`   - Bonjour service name for discovery, defaults to "wssensor"
* `duration`  - Duration of motion sensor events, defaults to 10 seconds
* `aliases`   - Friendly names for your sensor's

# Configuration - NodeMCU

See README in nodemcu directory

# Credits

* cflurin - Borrowed websocket implementation from homebridge-websocket
* Frank Edelhaeuser - Borrowed lua mDNS Discovery code, and updated to support NodeMCU
