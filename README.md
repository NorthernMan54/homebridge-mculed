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

* [x] Migrate from mDNS to bonjour
* [x] Plugin has a circular json issue in accessory
* [ ] Websocket socket level events in Plugin
* [ ] Complete documentation
* [x] Aliases don't appear to work
* [ ] Collapse the OTA Update server to nodeJS
* [ ] Identify method needs rework

# Backlog - nodemcu

* [x] OTA nodeMCU code provisioning
* [x] Initial lua code load via script
* [x] Websocket socket level events in NodeMCU
* [x] NodeMCU Memory leak from closed socket connections
* [x] Create schematic for nodeMCU
* [ ] Power nodemcu with DC-DC Step down from the 24V power supply
* [ ] Watchdog timer, what should it do
* [ ] What should the LED's do in a power cycle?
* [ ] Get a case with push button's
* [ ] Program second button to flip primary colors
* [ ] Complete documentation
* [ ] Remove excessive prints in nodeMCU code
* [ ] Power off LED strip via MOSFET -- Not sure if this works

# Roadmap

# Supported configurations

* [x] Costco LED Strip - Intertek 4005244 - This strip is based on the sm16703p LED controller chip


# Installation - homebridge-mculed

```
sudo npm install -g homebridge-mculed
```

# Configuration - homebridge-mculed

```
{
  "platform": "mculed",
  "name": "mculed",
  "aliases": {
    "NODE-2BA0FF": "Porch Motion"
  }
}
```

* `aliases`   - Friendly names for your sensor's

# Configuration - NodeMCU

See README in nodemcu directory

# Credits

* TerryE and Marcelstoer - For nodemcu/lua updates - https://github.com/nodemcu/nodemcu-firmware/tree/master/lua_examples/luaOTA
* Frank Edelhaeuser - Borrowed lua mDNS Discovery code, and updated to support NodeMCU
* creationix - Borrowed LUA WebSocket Server code - https://github.com/creationix/nodemcu-webide/tree/master/mcu
