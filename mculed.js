// Homebridge platform plugin supporting

'use strict';

var debug = require('debug')('MCULED');
var request = require("request");
var mdns = require('mdns');
const WebSocket = require('ws');
var inherits = require('util').inherits;
var Accessory, Service, Characteristic, UUIDGen, CustomCharacteristic, FakeGatoHistoryService;
const moment = require('moment');
var os = require("os");
var hostname = os.hostname();

module.exports = function(homebridge) {
  Accessory = homebridge.platformAccessory;
  Service = homebridge.hap.Service;
  Characteristic = homebridge.hap.Characteristic;
  UUIDGen = homebridge.hap.uuid;
  CustomCharacteristic = require('./lib/CustomCharacteristic.js')(homebridge);

  homebridge.registerPlatform("homebridge-mculed", "mculed", mculed);
}

function mculed(log, config, api) {
  this.log = log;
  this.accessories = {}; // MAC -> Accessory

  if (typeof(config.aliases) !== "undefined" && config.aliases !== null) {
    this.aliases = config.aliases;
  }

  if (api) {
    this.api = api;
    this.api.on('didFinishLaunching', this.didFinishLaunching.bind(this));
  }
}

mculed.prototype.configureAccessory = function(accessory) {

  this.log("configureAccessory %s", accessory.displayName);
  accessory.log = this.log;

  if (accessory.context.model.includes("CLED")) {
    // Add YL-69 Moisture sensor
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
      .on('set', this.setColorTemperature.bind(accessory));
  }

  accessory.context.ws = new WebSocket(accessory.context.url);

  accessory.context.ws.on('close', function() {
    this.log("Repopening closed connection", this.context.name);
    this.context.ws = new WebSocket(this.context.url);
  }.bind(accessory));

  accessory.context.ws.on('error', function() {
    this.log("Repopening error connection", this.context.name);
    this.context.ws = new WebSocket(this.context.url);
  }.bind(accessory));

  accessory.context.ws.on('message', function(message) {
    this.log("Message from", this.context.name, message.toString());
    onMessage.call(accessory, message.toString());
  }.bind(accessory));

  accessory.context.ws.on('open', function() {
    this.log("Opened, getting status from", this.context.name);
    this.context.ws.send('{ "cmd": "get", "func": "status" }');
  }.bind(accessory));

  var name = accessory.context.name;;
  this.accessories[name] = accessory;
}

function onMessage(response) {

  var message = JSON.parse(response);

  for (var k in message) {
    switch (k) {
      case "On":
        this.log("Setting %s on to %s", this.context.name, message[k]);
        this
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.On).updateValue(message[k]);
        break;
      case "Brightness":
        this.log("Setting %s brightness to %s", this.context.name, message[k]);
        this
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.Brightness).updateValue(message[k]);
        break;
      case "Saturation":
        //if (!message.pwm) {
        this.log("Setting %s saturation to %s", this.context.name, message[k]);
        this
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.Saturation).updateValue(message[k]);
        //}
        break;
      case "Hue":
        //if (!message.pwm) {
        this.log("Setting %s hue to %s", this.context.name, message[k]);
        this
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.Hue).updateValue(message[k]);
        //}
        break;
      case "ColorTemperature":
        //if (message.pwm) {
        this.log("Setting %s ColorTemperature to %s", this.context.name, message[k]);
        this
          .getService(Service.Lightbulb)
          .getCharacteristic(Characteristic.ColorTemperature).updateValue(message[k]);
        //}
        break;
      default:
        this.log.error("Unhandled message item", k);
    }
  }
}



mculed.prototype.didFinishLaunching = function() {

  // TODO: this.addResetSwitch();

  this.log("Starting mDNS listener");
  try {

    var sequence = [
      mdns.rst.DNSServiceResolve(),
      'DNSServiceGetAddrInfo' in mdns.dns_sd ? mdns.rst.DNSServiceGetAddrInfo() : mdns.rst.getaddrinfo({
        families: [4]
      }),
      mdns.rst.makeAddressesUnique()
    ];
    var browser = mdns.createBrowser(mdns.tcp('mculed'), {
      resolverSequence: sequence
    });
    browser.on('serviceUp', function(service) {
      this.log("Found MCULED device:", service.name);
      //            for (var i = 0; i < 5; i++) {

      mculed.prototype.mcuModel.call(this, "http://" + service.host + ":" + service.port + "/", function(err, model) {
        if (!err) {
          this.addMcuAccessory(service, model);
        } else {
          this.log("Error Adding MCULED Device", service.name, err.message);
        }
      }.bind(this));
      //            }
    }.bind(this));
    browser.on('serviceDown', function(service) {
      this.log("Service down: ", service);
      // Mark missing devices as unreachable
      this.deviceDown(service.name);
    }.bind(this));
    browser.on('error', handleError);
    browser.start();
  } catch (ex) {
    handleError(ex);
  }

}

// Am using the Identify function to validate a device, and if it doesn't respond
// remove it from the config

mculed.prototype.Identify = function(accessory, status, callback, that) {

  var self = this;

  if (that)
    self = that;

  //    self.log("Object: %s", JSON.stringify(accessory, null, 4));

  self.log("Identify Request %s", accessory.displayName);

  if (accessory.context.url) {

    httpRequest(accessory.context.url, "", "GET", function(err, response, responseBody) {
      if (err) {
        self.log("Identify failed %s", accessory.displayName, err.message);
        self.removeAccessory(accessory.displayName);
        callback(err, accessory.displayName);
      } else {
        self.log("Identify successful %s", accessory.displayName);
        callback(null, accessory.displayName);
      }
    }.bind(self));
  } else {
    callback(null, accessory.displayName);
  }

}

mculed.prototype.resetDevices = function(accessory, status, callback) {
  var self = this;
  this.log("Reset Devices", status);
  callback(null, status);

  if (status == "1") {

    for (var id in self.accessories) {
      var device = self.accessories[id];
      this.log("Reseting", id, device.displayName);
      mculed.prototype.Identify(device, status, function(err, status) {
        self.log("Done", status, err);
      }, self);
    }
    setTimeout(function() {
      accessory.getService(Service.Switch)
        .setCharacteristic(Characteristic.On, 0);
    }, 3000);
  }

}

mculed.prototype.mcuModel = function(url, callback) {
  const ws = new WebSocket(url);

  ws.on('open', function open() {
    ws.send('{ "cmd": "get", "func": "id" }');
  });

  ws.on('message', function incoming(data) {
    this.log(data.toString());
    ws.close();
    JSON.parse(data)
    callback(null, JSON.parse(data).Model);
  }.bind(this));

}

mculed.prototype.setOn = function(value, callback) {

  if (value != this.getService(Service.Lightbulb).getCharacteristic(Characteristic.On).value) {
    this.log("Turn ON %s %s", this.context.name, value);
    this.context.ws.send('{ "cmd": "set", "func": "on", "value": ' + value + ' }', function() {
      console.log("sent")
    });
  } else {
    this.log("Skipping Turn On %s", this.context.name);
  }
  callback();

}

mculed.prototype.setBrightness = function(value, callback) {

  if (value != this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Brightness).value) {
    this.log("Turn BR %s %s", this.context.name, value);
    this.context.ws.send('{ "cmd": "set", "func": "brightness", "value": ' + value + ' }', function() {
      console.log("sent")
    });
  } else {
    this.log("Skipping Turn Brightness %s", this.context.name);
  }
  callback();

}

mculed.prototype.setHue = function(value, callback) {

  if (value != this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Hue).value) {
    this.log("Turn HUE %s %s", this.context.name, value);
    this.context.ws.send('{ "cmd": "set", "func": "hue", "value": ' + value + ' }', function() {
      console.log("sent")
    });
  } else {
    this.log("Skipping Turn Hue %s", this.context.name);
  }
  callback();

}

mculed.prototype.setSaturation = function(value, callback) {

  if (value != this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Saturation).value) {
    this.log("Turn SAT %s %s", this.context.name, value, this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Saturation).value);
    this.context.ws.send('{ "cmd": "set", "func": "saturation", "value": ' + value + ' }', function() {
      console.log("sent")
    });
  } else {
    this.log("Skipping Turn SAT %s", this.context.name);
  }
  callback();

}

mculed.prototype.setColorTemperature = function(value, callback) {

  if (value != this.getService(Service.Lightbulb).getCharacteristic(Characteristic.ColorTemperature).value ||
    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Hue).value != 0 ||
    this.getService(Service.Lightbulb).getCharacteristic(Characteristic.Saturation).value != 0) {
    this.log("Turn CT %s %s", this.context.name, value);
    this.context.ws.send('{ "cmd": "set", "func": "ct", "value": ' + value + ' }', function() {
      console.log("sent")
    });
  } else {
    this.log("Skipping Turn ColorTemperature %s", this.context.name);
  }
  callback();

}


mculed.prototype.addMcuAccessory = function(device, model) {
  var self = this;
  var name = device.name;
  var host = device.host;
  var port = device.port;
  var url = "http://" + host + ":" + port + "/";
  self.url = url;
  self.name = name;
  var uuid = UUIDGen.generate(name);

  if (!self.accessories[name]) {

    var displayName;
    if (this.aliases)
      displayName = this.aliases[name];
    if (typeof(displayName) == "undefined") {
      displayName = name;
    }

    var accessory = new Accessory(name, uuid, 10);

    self.log("Adding MCULED Device:", name, displayName, model);
    accessory.context.model = model;
    accessory.context.url = url;
    accessory.context.name = name;
    accessory.context.displayName = displayName;


    if (model.includes("CLED")) {
      // Add YL-69 Moisture sensor
      accessory
        .addService(Service.Lightbulb)
        .getCharacteristic(Characteristic.On)
        .on('set', this.setOn.bind(this));

      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on('set', this.setBrightness.bind(this));
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Hue)
        .on('set', this.setHue.bind(this));
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Saturation)
        .on('set', this.setSaturation.bind(this));
      accessory
        .getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.ColorTemperature)
        .on('set', this.setColorTemperature.bind(this));
    }

    accessory.getService(Service.AccessoryInformation)
      .setCharacteristic(Characteristic.Manufacturer, "MCULED")
      .setCharacteristic(Characteristic.Model, model)
      .setCharacteristic(Characteristic.SerialNumber, hostname + "-" + name)
      .setCharacteristic(Characteristic.FirmwareRevision, require('./package.json').version);


    self.accessories[name] = accessory;
    self.api.registerPlatformAccessories("homebridge-mculed", "mculed", [accessory]);
  } else {
    self.log("Skipping %s", name);
    accessory = this.accessories[name];

    // Fix for devices moving on the network
    if (accessory.context.url != url) {
      debug("URL Changed", name);
      accessory.context.url = url;
    } else {
      debug("URL Same", name);
    }
    //        accessory.updateReachability(true);
  }
}

mculed.prototype.addResetSwitch = function() {
  var self = this;
  var name = "MCULED Reset Switch";

  var uuid = UUIDGen.generate(name);

  if (!self.accessories[name]) {
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

    self.accessories[name] = accessory;
    self.api.registerPlatformAccessories("homebridge-mculed", "mculed", [accessory]);
  }
}



// Mark down accessories as unreachable

mculed.prototype.deviceDown = function(name) {
  var self = this;
  if (self.accessories[name]) {
    var accessory = this.accessories[name];
    self.mcuModel(accessory.context.url, function(model) {
      //          accessory.updateReachability(false);
    })
  }
}

mculed.prototype.removeAccessory = function(name) {
  this.log("removeAccessory %s", name);
  var extensions = {
    a: "",
    b: "LS",
    c: "GD"
  };
  for (var extension in extensions) {
    this.log("removeAccessory %s", name + extensions[extension]);
    if (this.accessories[name + extensions[extension]]) {
      var accessory = this.accessories[name + extensions[extension]];
      this.api.unregisterPlatformAccessories("homebridge-mculed", "mculed", [accessory]);
      delete this.accessories[name + extensions[extension]];
      this.log("removedAccessory %s", name + extensions[extension]);
    }
  }
}


mculed.prototype.configurationRequestHandler = function(context, request, callback) {

  this.log("configurationRequestHandler");

}


// Set mDNS timeout to 5 seconds

function handleError(err) {
  switch (err.errorCode) {
    case mdns.kDNSServiceErr_Unknown:
      console.warn(err);
      setTimeout(createBrowser, 5000);
      break;
    default:
      console.warn(err);
  }
}
