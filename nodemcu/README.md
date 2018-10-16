# homebridge-wssensor ESP8266 LUA Code

LUA programs for a nodeMCU device to read various sensors and integrate into homebridge-wssensor.  Supports direct notification and alerting of motion events from a PIR motion sensor.

# Hardware

1. Bill of materials
   - nodeMCU / esp8266 dev kit

Sensor options

   - DHT22 Temperature / Humidity Sensor
   - BME280 Bosch DIGITAL HUMIDITY, PRESSURE AND TEMPERATURE SENSOR
   - AM312 PIR Monition Sensor  ( https://www.aliexpress.com/item/Mini-IR-Pyroelectric-Infrared-PIR-Motion-Human-Sensor-Automatic-Detector-Module-high-reliability-12mm-x-25mm/32749737125.html?spm=a2g0s.9042311.0.0.6ec74c4dwcSLq4 )
   - MPU 6050 Acceleration/gyroscope sensor aka GY-521 Breakout board

Garage Door
  - I used a 1 channel 5 volt relay
  - 2 Magnetic Reed contact switches

# Circuit Diagrams

## BME-MS

![BME-MS](ESP8266%20-%20WSSensor_bb.jpg)

![BME-MS](ESP8266%20-%20WSSensor_schem.jpg)

## AM312

Pinout

```
-- Gnd
-- Signal
-- VCC +5v
```

# nodeMCU Firmware

1. Using http://nodemcu-build.com, create a custom firmware containing at least
   these modules:

   `adc,bit,bme280,dht,file,gpio,i2c,mdns,net,node,tmr,uart,websocket,wifi`


2. Please use esptool to install the float firmware onto your nodemcu.  There are alot of guides for this, so I won't repeat it here.

# Configuration

1. WIFI Setup - Copy passwords_sample.lua to passwords.lua and add your wifi SSID and passwords.  Please note
   that the configuration supports multiple wifi networks, one per config line.
```
module.SSID["SSID1"] = { ssid="SSID1", pwd = "password" }
```

2. Set your device Model in config.lua - Either DHT-MS,  BME-MS, BME-GD, or ACL used by homebridge-wssensor to determine which sensor type to create in homebridge

```
module.Model = "DHT-MS"
or
module.Model = "BME-MS"
or
module.Model = "BME-GD"
or
module.Model = "ACL"
```

# Lua Program installation

1. I used nodemcu-uploader which is available here https://github.com/kmpm/nodemcu-uploader

2. Run the script upload.sh, this will upload all the lua files to your esp8266

3. Test your device by running test.lua

4. After you have completed testing, rename test.lua to init.lua
