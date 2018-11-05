# homebridge-mculed
Homebridge Plugin for NodeMCU Based ws2812/sm16703p led strip controller for RGB+W led strips

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
* [x] Plugin has a circular json issue in accessory, likely timeout
* [x] After reboot of the device, socket connection does not re-establish
* [x] Implement websocket ping
* [x] Websocket socket level events in Plugin
* [x] Not responding for closed socket
* [x] Handle device not turned on
* [x] Identify method and reset button needs rework
* [ ] Complete plugin documentation
* [x] Aliases don't appear to work

# Backlog - nodemcu

* [x] OTA nodeMCU code provisioning
* [x] Initial lua code load via script
* [x] Websocket socket level events in NodeMCU
* [x] NodeMCU Memory leak from closed socket connections
* [x] Implement websocket pong
* [x] Program second button to flip primary colors
* [ ] Remove excessive prints in nodeMCU code
* [x] Watchdog timer, what should it do - Reset after 5 minutes without HB connection
* [ ] What should the LED's do in a power cycle?
* [x] Get a case with push button's
* [x] Create schematic for nodeMCU
* [x] Create layout for perfboard
* [x] Power nodemcu with DC-DC Step down from the 24V power supply
* [x] Create a board level layout to use on a perf board
* [x] Construct production unit
* [ ] Complete nodemcu documentation
* [x] Power off LED strip via MOSFET -- Not possible
* [ ] Revisit perfboard layout, break perf board between nodemcu and output section, and rotate output section 90 degrees
* [ ] Build 3 more units cottage porch lights, xmas 1 and xmas 2

# Roadmap

* [ ] Collapse the OTA Update server to nodeJS


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
      "NODE-AC5812": "Kitchen Sink"
    }
  }
```

* `aliases`   - Friendly names for your sensor's

# Configuration - NodeMCU

See [README](nodemcu/README.md) in nodemcu directory

# Credits

* TerryE and Marcelstoer - For nodemcu/lua updates - https://github.com/nodemcu/nodemcu-firmware/tree/master/lua_examples/luaOTA
* Frank Edelhaeuser - Borrowed lua mDNS Discovery code, and updated to support NodeMCU
* creationix - Borrowed LUA WebSocket Server code - https://github.com/creationix/nodemcu-webide/tree/master/mcu
