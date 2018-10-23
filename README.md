# homebridge-mculed
Homebridge Plugin for NodeMCU Based ws2812 led strip controller for RGB+W led strips

# Design Concept

* Realtime device communications via WebSockets, and device discovery via mDNS
* Nodemcu creates a websocket server
* Nodemcu advertises websocket server onto network via mDNS
* Plugin discovers server by watching for mDNS advertisement
* NodeMCU sends message to plugin containing device config
* Plugin creates HK accessory for device ( Have ability to alias sensor name in config.json )
* Nodemcu sends device state changes in realtime to plugin via WebSockets
* OTA nodeMCU provisioning

# Backlog - plugin

* [ ] Websocket socket level events in Plugin
* [ ] Plugin has a circular json issue in accessory
* [ ] Complete documentation
* [ ] Aliases don't appear to work

# Backlog - nodemcu

* [x] OTA nodeMCU code provisioning
* [x] Initial lua code load via script
* [x] Websocket socket level events in NodeMCU
* [x] NodeMCU Memory leak from closed socket connections
* [x] Create schematic for nodeMCU
* [ ] Power nodemcu with DC-DC Step down from the 24V power supply
* [ ] Watchdog timer, what should it do
* [ ] What should the LED's do in a power cycle?
* [ ] Get a case
* [ ] Complete documentation
* [ ] Remove excessive prints in nodeMCU code
* [ ] Power off LED strip via MOSFET -- Not sure if this works

# Roadmap

# Supported configurations

* [x] Costco LED Strip - Intertek 4005244


# Installation - homebridge-mculed

```
sudo npm install -g homebridge-mculed
```

# Configuration - homebridge-mculed

```
{
  "platform": "mculed",
  "name": "mculed",
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
* `service`   - Bonjour service name for discovery, defaults to "mculed"
* `duration`  - Duration of motion sensor events, defaults to 10 seconds
* `aliases`   - Friendly names for your sensor's

# Configuration - NodeMCU

See README in nodemcu directory

# Credits

* TerryE and Marcelstoer - For nodemcu/lua updates - https://github.com/nodemcu/nodemcu-firmware/tree/master/lua_examples/luaOTA
* Frank Edelhaeuser - Borrowed lua mDNS Discovery code, and updated to support NodeMCU
* creationix - Borrowed LUA WebSocket Server code - https://github.com/creationix/nodemcu-webide/tree/master/mcu
