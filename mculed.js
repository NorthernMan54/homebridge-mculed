// Homebridge platform plugin supporting LED Light Strips

'use strict';

var debug = require('debug')('MCULED');
var bonjour = require('bonjour')();
const WebSocket = require('ws');
const packageConfig = require('./package.json');
var ip = require('ip');
var Accessory, Service, Characteristic, UUIDGen;
var sockets = {};
var keepAlive = {};
var accessories = {}; // Name -> Accessory

module.exports = function(homebridge) {
  Accessory = homebridge.platformAccessory;
  Service = homebridge.hap.Service;
  Characteristic = homebridge.hap.Characteristic;
  UUIDGen = homebridge.hap.uuid;

  homebridge.registerPlatform("homebridge-mculed", "mculed", mculed);
};

/**
 * Homebridge plugin to connect to nodeMCU devices via websockets
 * @param {aliases} config - Friendly names for your devices
 * @example
 * config.json sample
 * {
 *    "platform": "mculed",
 *    "name": "mculed",
 *    "aliases": {
 *     "NODE-AC5812": "Kitchen Sink"
 *   }
 * }
 */

function mculed(log, config, api) {
  this.log = log;
  // this.accessories = {}; // MAC -> Accessory

  if (typeof(config.aliases) !== "undefined" && config.aliases !== null) {
    this.aliases = config.aliases;
  }

  if (api) {
    this.api = api;
    this.api.on('didFinishLaunching', this.didFinishLaunching.bind(this));
  }

  this.log.info(
    '%s v%s, node %s, homebridge v%s',
    packageConfig.name, packageConfig.version, process.version, api.serverVersion
  );
}

/**
 * Called on startup of Homebridge, once per accessory
 * @kind function
 * @name configureAccessory
 */

mculed.prototype.configureAccessory = function(accessory) {
  this.log("configureAccessory %s", accessory.displayName);
  accessory.log = this.log;

  if (typeof(accessory.context.model) !== "undefined") {
    // Only for real devices
    if (accessory.context.model.includes("CLED")) {
      accessory
        .getService("Xmas " + accessory.context.displayName)
        .getCharacteristic(Characteristic.On)
        .on('set', this.setXmasOn.bind(accessory));
      accessory
        .getService("Mode " + accessory.context.displayName)
        .getCharacteristic(Characteristic.On)
        .on('set', this.setModeOn.bind(accessory));
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.On)
        .on('set', this.setOn.bind(accessory));
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on('set', this.setBrightness.bind(accessory));
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Hue)
        .on('set', this.setHue.bind(accessory));
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Saturation)
        .on('set', this.setSaturation.bind(accessory));
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.ColorTemperature)
        .setProps({
          minValue: 0
        })
        .on('set', this.setColorTemperature.bind(accessory));
      // Only open a socket connection for CLED devices
      if (typeof(accessory.context.url) !== "undefined") {
        openSocket.call(this, accessory);
      }
    }
  }

  if (accessory.context.name === "MCULED Reset Switch") {
    accessory.getService(Service.Switch)
      .getCharacteristic(Characteristic.On)
      .on('set', this.resetDevices.bind(this, accessory));
  }
  accessories[accessory.context.name] = accessory;
};

/**
 * This function opens a socket connection to the nodeMCU device
 */

function openSocket(accessory) {
  sockets[accessory.context.name] = new WebSocket(accessory.context.url, {
    "timeout": 10000
  });

  sockets[accessory.context.name].on('close', function() {
    this.log("Repopening closed connection", accessory.context.name);
    setTimeout(function() {
      openSocket.call(this, accessory);
    }.bind(this), 10000);
  }.bind(this));

  sockets[accessory.context.name].on('error', function() {
    this.log.error("Socket error connection", accessory.context.name);
  }.bind(this));

  sockets[accessory.context.name].on('message', function(message) {
    this.log("Message from", accessory.context.name, message.toString());
    onMessage.call(this, accessory, message.toString());
  }.bind(this));

  sockets[accessory.context.name].on('open', function() {
    this.log.debug("Connection opened, getting status from", accessory.context.name);
    sockets[accessory.context.name].send('{ "cmd": "get", "func": "status" }');
  }.bind(this));

  keepAlive[accessory.context.name] = setInterval(function ping() {
    // this.log.debug("ping", accessory.context.name, sockets[accessory.context.name].readyState);
    if (sockets[accessory.context.name].readyState === WebSocket.OPEN) {
      sockets[accessory.context.name].ping(" ");
    } else { //
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.On).updateValue(new Error("Not responding"));
    }
  }, 10000);
}

/**
 * Parsing of messages received nodeMCU devices
 */

function onMessage(accessory, response) {
  var message = JSON.parse(response);

  for (var k in message) {
    switch (k) {
      case "On":
        // this.log("Setting %s on to %s", accessory.context.name, message[k]);
        accessory
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.On).updateValue(message[k]);
        break;
      case "Brightness":
        // this.log("Setting %s brightness to %s", accessory.context.name, message[k]);
        accessory
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.Brightness).updateValue(message[k]);
        break;
      case "Saturation":
        // this.log("Setting %s saturation to %s", accessory.context.name, message[k]);
        accessory
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.Saturation).updateValue(message[k]);
        break;
      case "Hue":
        // this.log("Setting %s hue to %s", accessory.context.name, message[k]);
        accessory
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.Hue).updateValue(message[k]);
        break;
      case "ColorTemperature":
        // this.log("Setting %s ColorTemperature to %s", accessory.context.name, message[k]);
        accessory
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.ColorTemperature).updateValue(message[k]);
        break;
      case "pwm":
        // No need to action pwm
        break;
      default:
        this.log.error("Unhandled message item", k);
    }
  }
}

/**
 * Send message to nodeMCU device
 */

function wsSend(message, callback) {
  // this.log.debug("send", this.context.name, sockets[this.context.name].readyState);
  if (sockets[this.context.name].readyState === WebSocket.OPEN) {
    sockets[this.context.name].send(message, callback);
  } else { //
    callback(new Error("Not responding"));
  }
}

/**
 * Called on startup of Homebridge, after initialization is complete
 * Discover mculed devices using mDNS/Bonjour
 * Creates homebridge device, once per discovered accessory
 * @kind function
 * @name didFinishLaunching
 */

mculed.prototype.didFinishLaunching = function() {
  this.addResetSwitch();
  this.log("Starting bonjour listener");

  try {
    bonjour.find({
      type: 'mculed'
    }, function(service) {
      // debug('Found an HAP server:', service);
      debug("mculed discovered", service.name, service.addresses);
      var hostname;
      for (let address of service.addresses) {
        if (ip.isV4Format(address)) {
          hostname = address;
          break;
        }
      }

      debug("HAP instance address: %s -> %s -> %s", service.name, service.host, hostname);
      mculed.prototype.mcuModel.call(this, "http://" + service.host + ":" + service.port + "/", function(err, model) {
        if (!err) {
          this.addMcuAccessory(service, model);
        } else {
          this.log("Error Adding MCULED Device", service.name, err.message);
        }
      }.bind(this));
    }.bind(this));
  } catch (ex) {
    handleError(ex);
  }
};

/**
 * Call nodeMCU device and return configuration string
 * @kind function
 * @name mcuModel
 * @param {string} url - URL of nodeMCU device
 * @param {function} callback - Callback function to call when message or received
 */

mculed.prototype.mcuModel = function(url, callback) {
  const ws = new WebSocket(url);

  ws.on('open', function open() {
    ws.send('{ "cmd": "get", "func": "id" }');
  });

  ws.on('error', function error(err) {
    callback(err);
  });

  ws.on('message', function incoming(data) {
    this.log(data.toString());
    ws.close();
    ws.terminate();
    JSON.parse(data);
    callback(null, JSON.parse(data).Model);
  }.bind(this));
};

/**
 * Turn on nodeMCU device
 * @kind function
 * @name setOn
 */

mculed.prototype.setOn = function(value, callback) {
  if (value !== this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).value) {
    this.log("Turn ON %s %s", this.context.name, value);
    wsSend.call(this, '{ "cmd": "set", "func": "on", "value": ' + value + ' }', function(err) {
      callback(err);
    });
  } else {
    this.log("Skipping Turn On %s", this.context.name);
    callback();
  }
};

/**
 * Turn on and rotate thru the primary colors
 * @kind function
 * @name setModeOn
 */

mculed.prototype.setModeOn = function(value, callback) {
  if (value) {
    // if (value !== this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).value) {
    this.log("Turn Mode %s %s", this.context.name, value);
    wsSend.call(this, '{ "cmd": "set", "func": "mode", "value": "traditional", "param": 500 }', function(err) {
      callback(err);
    });

    // Turn off virtual switch after 3 seconds

    setTimeout(function() {
      this.getService(Service.Switch)
        .setCharacteristic(Characteristic.On, false);
    }.bind(this), 3000);
  } else {
    callback(null, value);
  }
};

/**
 * Turn on and rotate thru the primary colors
 * @kind function
 * @name setXmasOn
 */

mculed.prototype.setXmasOn = function(value, callback) {
  if (value) {

    this.context.xmasValue = this.context.xmasValue + 120;

    if (this.context.xmasValue > 359) {
      this.context.xmasValue = 0;
    }

    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Hue).setValue(this.context.xmasValue);
    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Saturation).setValue(100);
    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Brightness).setValue(100);

    // Turn off virtual switch after 3 seconds

    setTimeout(function() {
      this.getService("Xmas " + this.context.displayName)
        .setCharacteristic(Characteristic.On, false);
    }.bind(this), 3000);
  }

  callback(null, value);
};

/**
 * Set brightness of nodeMCU device
 * @kind function
 * @name setBrightness
 */

mculed.prototype.setBrightness = function(value, callback) {
  // If device is off, turn it on
  if (!this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).value) {
    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).setValue(true, function() {
      debug("Callback-setBrightness");
      this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Brightness).setValue(value, callback);
    }.bind(this));
  } else {
    if (value !== this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Brightness).value) {
      this.log("Turn BR %s %s", this.context.name, value);
      wsSend.call(this, '{ "cmd": "set", "func": "brightness", "value": ' + value + ' }', function(err) {
        callback(err);
      });
    } else {
      this.log("Skipping Turn Brightness %s", this.context.name);
      callback();
    }
  }
};

/**
 * Set hue of nodeMCU device
 * @kind function
 * @name setHue
 */

mculed.prototype.setHue = function(value, callback) {
  // If device is off, turn it on
  if (!this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).value) {
    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).setValue(true, function() {
      debug("Callback-setHue");
      this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Hue).setValue(value, callback);
    }.bind(this));
  } else {
    if (value !== this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Hue).value) {
      this.log("Turn HUE %s %s", this.context.name, value);
      wsSend.call(this, '{ "cmd": "set", "func": "hue", "value": ' + value + ' }', function(err) {
        callback(err);
      });
    } else {
      this.log("Skipping Turn Hue %s", this.context.name);
      callback();
    }
  }
};

/**
 * Set color saturation of nodeMCU device
 * @kind function
 * @name setSaturation
 */

mculed.prototype.setSaturation = function(value, callback) {
  // If device is off, turn it on
  if (!this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).value) {
    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).setValue(true, function() {
      debug("Callback-setSaturation");
      this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Saturation).setValue(value, callback);
    }.bind(this));
  } else {
    if (value !== this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Saturation).value) {
      this.log("Turn SAT %s %s", this.context.name, value, this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Saturation).value);
      wsSend.call(this, '{ "cmd": "set", "func": "saturation", "value": ' + value + ' }', function(err) {
        callback(err);
      });
    } else {
      this.log("Skipping Turn SAT %s", this.context.name);
      callback();
    }
  }
};

/**
 * Set color temperature of nodeMCU device
 * @kind function
 * @name setColorTemperature
 */

mculed.prototype.setColorTemperature = function(value, callback) {
  // If device is off, turn it on
  if (!this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).value) {
    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).setValue(true, function() {
      debug("Callback-setSaturation");
      this.getService(Service.Lightbulb).getCharacteristic(Characteristic.ColorTemperature).setValue(value, callback);
    }.bind(this));
  } else {
    if (value !== this.getService(Service.Lightbulb).getCharacteristic(Characteristic.ColorTemperature).value ||
      this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Hue).value !== 0 ||
      this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Saturation).value !== 0) {
      this.log("Turn CT %s %s", this.context.name, value);
      wsSend.call(this, '{ "cmd": "set", "func": "ct", "value": ' + value + ' }', function(err) {
        callback(err);
      });
    } else {
      this.log("Skipping Turn ColorTemperature %s", this.context.name);
      callback();
    }
  }
};

/**
 * Add MCU Device
 * @kind function
 * @name addMcuAccessory
 */

mculed.prototype.addMcuAccessory = function(device, model) {
  if (!accessories[device.name]) {
    var uuid = UUIDGen.generate(device.name);
    var displayName;
    if (this.aliases) {
      displayName = this.aliases[device.name];
    }
    if (typeof(displayName) === "undefined") {
      displayName = device.name;
    }

    var accessory = new Accessory(displayName, uuid, 10);

    this.log("Adding MCULED Device:", device.name, displayName, model);
    accessory.context.model = model;
    accessory.context.url = "http://" + device.host + ":" + device.port + "/";
    accessory.context.name = device.name;
    accessory.context.displayName = displayName;
    accessory.context.xmasValue = 0;

    if (model.includes("CLED")) {
      accessory
        .addService(Service.Lightbulb);
      accessory.addService(Service.Switch, "Mode " + displayName, "Mode");
      accessory.addService(Service.Switch, "Xmas " + displayName, "Xmas");
      //accessory.setPrimaryService(accessory
      //.getService(Service.Lightbulb));
    }

    accessory.getService(Service.AccessoryInformation)
      .setCharacteristic(Characteristic.Manufacturer, "MCULED")
      .setCharacteristic(Characteristic.Model, model)
      .setCharacteristic(Characteristic.SerialNumber, device.name)
      .setCharacteristic(Characteristic.FirmwareRevision, require('./package.json').version);

    mculed.prototype.configureAccessory.call(this, accessory);
    accessories[device.name] = accessory;
    this.api.registerPlatformAccessories("homebridge-mculed", "mculed", [accessory]);
  } else {
    accessory = accessories[device.name];

    // Fix for devices moving on the network
    if (accessory.context.url !== "http://" + device.host + ":" + device.port + "/") {
      debug("URL Changed", device.name);
      accessory.context.url = "http://" + device.host + ":" + device.port + "/";
    } else {
      debug("URL Same", device.name);
    }
  }
};

/**
 * Reset switch checks if each device is on the network and if it isn't found, removes it
 * @kind function
 * @name addResetSwitch
 */

mculed.prototype.addResetSwitch = function() {
  var self = this;
  var name = "MCULED Reset Switch";

  var uuid = UUIDGen.generate(name);

  if (!accessories[name]) {
    var accessory = new Accessory(name, uuid, 10);

    self.log("Adding Reset Switch:");
    accessory.context.name = name;
    //        accessory.context.model = model;
    //        accessory.context.url = url;

    accessory.addService(Service.Switch, name)
      .getCharacteristic(Characteristic.On)
      .on('set', self.resetDevices.bind(self, accessory));

    accessory.getService(Service.AccessoryInformation)
      .setCharacteristic(Characteristic.Manufacturer, "MCULED")
      .setCharacteristic(Characteristic.Model, name)
      .setCharacteristic(Characteristic.SerialNumber, "123456");

    accessories[name] = accessory;
    self.api.registerPlatformAccessories("homebridge-mculed", "mculed", [accessory]);
  }
};

mculed.prototype.removeAccessory = function(name) {
  this.log("removeAccessory %s", name);

  var accessory = accessories[name];
  this.api.unregisterPlatformAccessories("homebridge-mculed", "mculed", [accessory]);
  delete accessories[name];
  sockets[name].terminate();
  sockets[name] = null;
  clearInterval(keepAlive[name]);
  this.log("removedAccessory %s", name);
};

mculed.prototype.configurationRequestHandler = function(context, request, callback) {
  this.log("configurationRequestHandler");
};

/**
 * Am using the Identify function to validate a device, and if it doesn't respond
 * remove it from the config
 * @kind function
 * @name Identify
 */

mculed.prototype.Identify = function(accessory, status, callback) {
  this.log("Identify Request %s", accessory.displayName);

  if (accessory.context.url) {
    mculed.prototype.mcuModel.call(this, accessory.context.url, function(err, response) {
      if (err) {
        this.log("Identify failed %s", accessory.displayName, err.message);
        this.removeAccessory(accessory.context.name);
        callback(err, accessory.displayName);
      } else {
        this.log("Identify successful %s", accessory.displayName);
        callback(null, accessory.displayName);
      }
    }.bind(this));
  } else {
    callback(null, accessory.displayName);
  }
};

mculed.prototype.resetDevices = function(accessory, status, callback) {
  this.log("Reset Devices", status);
  callback(null, status);

  if (status) {
    for (var id in accessories) {
      var device = accessories[id];
      this.log("Checking", id, device.displayName);
      mculed.prototype.Identify.call(this, device, status, function(err, status) {
        this.log("Done", status, err);
      }.bind(this));
    }
    setTimeout(function() {
      accessory.getService(Service.Switch)
        .setCharacteristic(Characteristic.On, false);
    }, 3000);
  }
};

function handleError(err) {
  switch (err.errorCode) {
    default:
      console.warn(err);
  }
}
