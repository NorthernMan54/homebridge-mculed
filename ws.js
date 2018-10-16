// Sample Config
//{
//  "platform": "wssensor",
//  "name": "wssensor",
//  "port": 8080,
//  "refresh": "60",
//  "leak": "10",
//  "aliases": {
//    "NODE-2BA0FF": "Porch Motion"
//  }
//}

'use strict';

var util = require('util');
var Utils = require('./lib/utils.js').Utils;
var WsSensorAccessory = require('./lib/accessory.js').Accessory;
var Websocket = require('./lib/websocket.js').Websocket;
var debug = require('debug')('wssensor');
var Advertise = require('./lib/advertise.js').Advertise;
var WebSocket = require('ws');
const moment = require('moment');
var os = require("os");
var hostname = os.hostname();

var Accessory, Service, Characteristic, UUIDGen, CustomCharacteristic, FakeGatoHistoryService;
var cachedAccessories = 0;
var count = 0;

var platform_name = "wssensor";
var plugin_name = "homebridge-" + platform_name;

module.exports = function(homebridge) {
  console.log("homebridge API version: " + homebridge.version);

  CustomCharacteristic = require('./lib/CustomCharacteristic.js')(homebridge);
  FakeGatoHistoryService = require('fakegato-history')(homebridge);

  Accessory = homebridge.platformAccessory;

  Service = homebridge.hap.Service;
  Characteristic = homebridge.hap.Characteristic;
  UUIDGen = homebridge.hap.uuid; // Universally Unique IDentifier

  homebridge.registerPlatform(plugin_name, platform_name, WsSensorPlatform, true);
}

function WsSensorPlatform(log, config, api) {

  this.log = log;
  this.accessories = {};

  debug("config = %s", JSON.stringify(config));

  if (typeof(config) !== "undefined" && config !== null) {
    this.port = config.port || {
      "port": 4050
    };
    this.refresh = config['refresh'] || 60; // Update every minute
    this.storage = config.storage || "fs";
    this.duration = config['duration'] || 10; // Duration of on event in seconds ( ACL )
    this.sensitivity = config['sensitivity'] || 400; // Sensitivity of sensor ( ACL )
    this.service = config['service'] || "wssensor";

  } else {
    this.log.error("config undefined or null!");
    return
  }

  if (typeof(config.aliases) !== "undefined" && config.aliases !== null) {
    this.aliases = config.aliases;
  }


  var plugin_version = Utils.readPluginVersion();
  this.log("%s v%s", plugin_name, plugin_version);

  var params = {
    "log": this.log,
    "plugin_name": plugin_name,
    "port": this.port,
    "accessories": this.accessories,
    "Characteristic": Characteristic,
    "addAccessory": this.addAccessory.bind(this),
    "getAccessories": this.getAccessories.bind(this),
    "sendEvent": this.sendEvent.bind(this)
  }
  this.Websocket = new Websocket(params);

  this.Advertise = new Advertise(params);

  Utils.read_npmVersion(plugin_name, function(npm_version) {
    if (npm_version > plugin_version) {
      this.log("A new version %s is avaiable", npm_version);
    }
  }.bind(this));

  if (api) {
    this.api = api;

    this.api.on('didFinishLaunching', function() {
      this.log("Plugin - DidFinishLaunching");

      this.Websocket.startServer();
      this.Advertise.createAdvertisement(this.service);


      debug("Number of cached Accessories: %s", cachedAccessories);
      this.log("Number of Accessories: %s", Object.keys(this.accessories).length);


    }.bind(this));
    //debug("WsSensorPlatform %s", JSON.stringify(this.accessories));

    setInterval(function() {
      for (var k in this.accessories) {

        var ws = this.accessories[k].ws;
        debug("Poll", k, ++count);
        if (ws && ws.readyState === WebSocket.OPEN) {
          var msg = {
            "count": count,
            "sensitivity": this.sensitivity,
            "duration": this.duration
          }
          ws.send(JSON.stringify(msg, null, 2));
        } else {
          this.log("No socket", k);
          this.accessories[k].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.CurrentTemperature)
            .updateValue(new Error("Not Responding"));
          //          this.accessories[k].getService(Service.MotionSensor).getCharacteristic(Characteristic.MotionDetected)
          //            .updateValue(new Error("Not Responding"));
        }

      }
    }.bind(this), this.refresh * 1000);


  }
}

//{ "Hostname": "NODE-2BA0FF", "Model": "MS", "Version": "2.0", "Firmware": "2.1.0", "Data": {  "Motion": "1" }}


WsSensorPlatform.prototype.sendEvent = function(err, message) {

  if (err) {
    this.log("Not sending event due to Error");
  } else {

    var name = message.Hostname;

    for (var k in message.Data) {
      //      debug(k, message.Data[k]);
      switch (k) {
        case "Motion":
          var value = message.Data[k] > 0;
          if (this.accessories[name].getService(Service.MotionSensor).getCharacteristic(Characteristic.MotionDetected).value != value) {
            this.accessories[name].getService(Service.MotionSensor).getCharacteristic(CustomCharacteristic.LastActivation)
              .updateValue(moment().unix() - this.accessories[name].mLoggingService.getInitialTime());
          }
          this.accessories[name].getService(Service.MotionSensor).getCharacteristic(Characteristic.MotionDetected)
            .updateValue(value);
          this.accessories[name].mLoggingService.addEntry({
            time: moment().unix(),
            status: value
          });
          break;
        case "CurrentDoorState":
          var value = message.Data[k];

          if (this.accessories[name].getService(Service.GarageDoorOpener)
            .getCharacteristic(Characteristic.CurrentDoorState).value != value) {
            // Only update on change in value
            this.accessories[name].getService(Service.GarageDoorOpener).getCharacteristic(CustomCharacteristic.LastActivation)
              .updateValue(moment().unix() - this.accessories[name].mLoggingService.getInitialTime());
            if (value == 0) {
              // Only when opened
              this.accessories[name].getService(Service.GarageDoorOpener).getCharacteristic(CustomCharacteristic.TimesOpened)
                .updateValue(this.accessories[name].getService(Service.GarageDoorOpener).getCharacteristic(CustomCharacteristic.TimesOpened).value + 1);
            }
            if (value < 2) {
              // Only when opened and closed
              this.accessories[name].mLoggingService.addEntry({
                time: moment().unix(),
                status: value % 2
              });
            }
          }

          this.accessories[name].getService(Service.GarageDoorOpener).getCharacteristic(Characteristic.CurrentDoorState)
            .updateValue(value);
          debug("CDS %s, TDS %s", value, value % 2);
          this.accessories[name].getService(Service.GarageDoorOpener).getCharacteristic(Characteristic.TargetDoorState)
            .updateValue(value % 2);


          break;
        case "Trigger":
          var value = (message.Data[k] ? 1 : 0);
          debug("Trigger", value);
          this.accessories[name].getService(Service.MotionSensor).getCharacteristic(Characteristic.MotionDetected)
            .updateValue(value);
          this.accessories[name].getService(Service.MotionSensor).getCharacteristic(CustomCharacteristic.LastActivation)
            .updateValue(moment().unix() - this.accessories[name].mLoggingService.getInitialTime());
          this.accessories[name].mLoggingService.addEntry({
            time: moment().unix(),
            status: value
          });
          break;

        case "Temperature":
          var value = message.Data[k];
          this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.CurrentTemperature)
            .updateValue(value);
          break;

        case "Humidity":
          var value = message.Data[k];
          this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.CurrentRelativeHumidity)
            .updateValue(value);
          break;

        case "Barometer":
          var value = message.Data[k];
          this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(CustomCharacteristic.AtmosphericPressureLevel)
            .updateValue(value);
          break;

        case "Status":
          var value = message.Data[k];
          switch (value) {
            case 0:
              //              this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusActive)
              //                .updateValue(true);
              //              this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusFault)
              //                .updateValue(Characteristic.StatusFault.NO_FAULT);
              this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusLowBattery)
                .updateValue(Characteristic.StatusLowBattery.BATTERY_LEVEL_NORMAL);
              //              this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusTampered)
              //                .updateValue(Characteristic.StatusTampered.NOT_TAMPERED);
              break;
            default:
              //              this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusActive)
              //                .updateValue(false);
              //              this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusFault)
              //                .updateValue(Characteristic.StatusFault.GENERAL_FAULT);
              this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusLowBattery)
                .updateValue(Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW);
              //              this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusTampered)
              //                .updateValue(Characteristic.StatusTampered.TAMPERED);
          }
      }
    }

    //  this.accessories[name].wLoggingService.addEntry({
    //    time: moment().unix(),
    //    temp: roundInt(message.Data.Temperature),
    //    pressure: roundInt(message.Data.Barometer),
    //    humidity: roundInt(message.Data.Humidity)
    //  });

  }
}

WsSensorPlatform.prototype.setDuration = function(value, callback) {
  debug("setDuration");
  this.duration = value;
  callback();
}

WsSensorPlatform.prototype.setTargetDoorState = function(accessory, value, callback) {
  this.log("setTargetDoorState Request", accessory.displayName, value);
  var msg = {
    "count": count,
    "button": 300
  }

  if (accessory.getService(Service.GarageDoorOpener).getCharacteristic(Characteristic.TargetDoorState).value != value) {
    if (accessory.ws && accessory.ws.readyState === WebSocket.OPEN) {
      accessory.ws.send(JSON.stringify(msg, null, 2));
      callback();
    } else {
      this.log("No socket", accessory.displayName);
      callback(new Error("No socket"));
    }
  } else {
    this.log("No controlling door, door already open/closed");
    callback();
  }

}

WsSensorPlatform.prototype.setSensitivity = function(value, callback) {

  debug("setSensitivity");
  this.sensitivity = value;
  callback();
}

WsSensorPlatform.prototype.identify = function(accessory, value, callback) {

  if (accessory.ws && accessory.ws.readyState === WebSocket.OPEN) {
    this.log("Not removing", accessory.displayName);
  } else {
    this.log("Removing", accessory.displayName, accessory.context.hostname);
    this.api.unregisterPlatformAccessories("homebridge-wssensor", "wssensor", [accessory]);
    delete this.accessories[accessory.context.hostname];
  }
  callback();
}


WsSensorPlatform.prototype.setResetTotal = function(value, callback) {
  debug("setResetTotal");
  this.getService(Service.GarageDoorOpener).getCharacteristic(CustomCharacteristic.TimesOpened).updateValue(0);
  callback();
}

WsSensorPlatform.prototype.addAccessory = function(accessoryDef, ws) {

  var name = accessoryDef.Hostname;
  var displayName = this.aliases[name];
  if (typeof(displayName) == "undefined")
    displayName = name;

  var ack, message;
  var isValid;

  this.log("addAccessory", name, displayName);

  if (!this.accessories[name]) {
    var uuid = UUIDGen.generate(name);

    var newAccessory = new Accessory(displayName, uuid);
    newAccessory.reachable = true;
    newAccessory.context.service_name = accessoryDef.Model;
    newAccessory.context.hostname = name;
    newAccessory.ws = ws;

    newAccessory.getService(Service.AccessoryInformation)
      .setCharacteristic(Characteristic.Manufacturer, "WSSENSOR")
      .setCharacteristic(Characteristic.Model, accessoryDef.Model + " " + accessoryDef.Version)
      .setCharacteristic(Characteristic.FirmwareRevision, require('./package.json').version)
      .setCharacteristic(Characteristic.SerialNumber, hostname + "-" + name);

    newAccessory.on('identify', this.identify.bind(this, newAccessory));

    var sensors = accessoryDef.Model.split('-');

    newAccessory.context.history = "weather";

    for (var i = 0; i < sensors.length; i++) {
      switch (sensors[i]) {
        case "GD":
          newAccessory.addService(Service.GarageDoorOpener, displayName + " Door")
            .getCharacteristic(Characteristic.TargetDoorState)
            .on('set', this.setTargetDoorState.bind(this, newAccessory));
          newAccessory
            .getService(Service.GarageDoorOpener)
            .addCharacteristic(CustomCharacteristic.LastActivation);
          newAccessory
            .getService(Service.GarageDoorOpener).addCharacteristic(CustomCharacteristic.OpenDuration)
          newAccessory
            .getService(Service.GarageDoorOpener).addCharacteristic(CustomCharacteristic.ClosedDuration)
          newAccessory
            .getService(Service.GarageDoorOpener).addCharacteristic(CustomCharacteristic.TimesOpened);
          newAccessory
            .getService(Service.GarageDoorOpener).addCharacteristic(CustomCharacteristic.ResetTotal);
          newAccessory
            .getService(Service.GarageDoorOpener).getCharacteristic(CustomCharacteristic.ResetTotal)
            .on('set', this.setResetTotal.bind(newAccessory));
          newAccessory.context.history = "door";
          break;
        case "MS":
          newAccessory.addService(Service.MotionSensor, displayName);
          newAccessory
            .getService(Service.MotionSensor)
            .addCharacteristic(CustomCharacteristic.Sensitivity);
          newAccessory
            .getService(Service.MotionSensor)
            .getCharacteristic(CustomCharacteristic.Sensitivity)
            .on('set', this.setSensitivity.bind(this));
          newAccessory
            .getService(Service.MotionSensor)
            .addCharacteristic(CustomCharacteristic.LastActivation);
          newAccessory
            .getService(Service.MotionSensor)
            .addCharacteristic(CustomCharacteristic.Duration);
          newAccessory
            .getService(Service.MotionSensor)
            .getCharacteristic(CustomCharacteristic.Duration)
            .on('set', this.setDuration.bind(this));
          newAccessory.context.history = "motion";
          break;
        case "BME":
          newAccessory.addService(Service.TemperatureSensor, displayName)
            .getCharacteristic(Characteristic.CurrentTemperature)
            .setProps({
              minValue: -100,
              maxValue: 100
            });
          newAccessory
            .getService(Service.TemperatureSensor)
            .addCharacteristic(Characteristic.CurrentRelativeHumidity);
          newAccessory
            .getService(Service.TemperatureSensor)
            .addCharacteristic(CustomCharacteristic.AtmosphericPressureLevel);
          break;
        case "DHT":
          newAccessory.addService(Service.TemperatureSensor, displayName)
            .getCharacteristic(Characteristic.CurrentTemperature)
            .setProps({
              minValue: -100,
              maxValue: 100
            });
          newAccessory
            .getService(Service.TemperatureSensor)
            .addCharacteristic(Characteristic.CurrentRelativeHumidity);
          newAccessory
            .getService(Service.TemperatureSensor)
            .addCharacteristic(CustomCharacteristic.AtmosphericPressureLevel);
          break;
        case "ACL":
          newAccessory.addService(Service.MotionSensor, displayName);
          newAccessory
            .getService(Service.MotionSensor)
            .addCharacteristic(CustomCharacteristic.Sensitivity);
          newAccessory
            .getService(Service.MotionSensor)
            .addCharacteristic(CustomCharacteristic.Duration);
          newAccessory
            .getService(Service.MotionSensor)
            .addCharacteristic(CustomCharacteristic.LastActivation);
          newAccessory.addService(Service.TemperatureSensor, displayName)
            .getCharacteristic(Characteristic.CurrentTemperature)
            .setProps({
              minValue: -100,
              maxValue: 100
            });
          newAccessory.context.history = "motion";
          break;
        default:
          this.log.error("Unknown Sensor Type", sensors[i], name, displayName);
      }
    }
    newAccessory.log = this.log;
    newAccessory.mLoggingService = new FakeGatoHistoryService(newAccessory.context.history, newAccessory, {
      storage: this.storage,
      minutes: this.refresh * 10 / 60
    });

    //    newAccessory.wLoggingService = new FakeGatoHistoryService("weather", newAccessory, {
    //      storage: this.storage,
    //      minutes: this.refresh * 10 / 60
    //    });

    this.accessories[name] = newAccessory;
    this.api.registerPlatformAccessories(plugin_name, platform_name, [newAccessory]);

  } else {
    debug("accessory already created");
  }
}

WsSensorPlatform.prototype.configureAccessory = function(accessory) {

  //debug("configureAccessory %s", JSON.stringify(accessory.services, null, 2));

  cachedAccessories++;
  var name = accessory.context.hostname;

  debug("Configuring", accessory.context);

  this.accessories[name] = accessory;

  accessory.on('identify', this.identify.bind(this, accessory));

  if (accessory.getService(Service.GarageDoorOpener)) {
    accessory.getService(Service.GarageDoorOpener)
      .getCharacteristic(Characteristic.TargetDoorState)
      .on('set', this.setTargetDoorState.bind(this, accessory));
    accessory.getService(Service.GarageDoorOpener)
      .getCharacteristic(CustomCharacteristic.ResetTotal)
      .on('set', this.setResetTotal.bind(accessory));
  }
  accessory.log = this.log;
  accessory.mLoggingService = new FakeGatoHistoryService(accessory.context.history, accessory, {
    storage: this.storage,
    minutes: this.refresh * 10 / 60
  });

  //  accessory.wLoggingService = new FakeGatoHistoryService("weather", accessory, {
  //    storage: this.storage,
  //    minutes: this.refresh * 10 / 60
  //  });

  this.log("configureAccessory", name);
}

WsSensorPlatform.prototype.getAccessories = function(name) {

  var accessories = {};
  var def = {};
  var service, characteristics;

  switch (name) {
    case "all":
      for (var k in this.accessories) {
        //this.log("getAccessories %s", JSON.stringify(this.accessories[k], null, 2));
        service = this.accessories[k].service_name;
        characteristics = this.accessories[k].i_value;
        def = {
          "service": service,
          "characteristics": characteristics
        };
        accessories[k] = def;
      }
      break;

    default:
      service = this.accessories[name].service_name;
      characteristics = this.accessories[name].i_value;
      def = {
        "service": service,
        "characteristics": characteristics
      };
      accessories[name] = def;
  }

  //this.log("getAccessory %s", JSON.stringify(accessories, null, 2));
  this.Websocket.sendAccessories(accessories);
}

WsSensorPlatform.prototype.buildParams = function(accessoryDef) {

  var params = {
    "accessoryDef": accessoryDef,
    "log": this.log,
    "Service": Service,
    "Characteristic": Characteristic,
    "WebSocket": this.WebSocket
  }
  debug("configureAccessories %s", JSON.stringify(params));
  return params;
}

function roundInt(string) {
  return Math.round(parseFloat(string) * 10) / 10;
}
