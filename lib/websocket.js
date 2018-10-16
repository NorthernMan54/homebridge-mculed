'use strict';

var util = require('util');
var path = require('path');
var Utils = require('./utils.js').Utils;
var debug = require('debug')('websocket');
var port, plugin_name, accessories, Characteristic, addAccessory, removeAccessory, getAccessories, sendEvent;
var latest, get_timeout, set_timeout, pre_name, pre_c;

var WebSocketServer = require('ws').Server,
  http = require('http'),
  express = require('express'),
  app = express();

var WebSocket = require('ws');

module.exports = {
  Websocket: Websocket
}

function Websocket(params) {

  this.log = params.log;
  port = params.port;
  plugin_name = params.plugin_name;
  accessories = params.accessories;
  Characteristic = params.Characteristic;
  addAccessory = params.addAccessory;
  removeAccessory = params.removeAccessory;
  getAccessories = params.getAccessories;
  sendEvent = params.sendEvent;

  this.ws;
}


Websocket.prototype.startServer = function() {

  var server = http.createServer(app);
  server.listen(port, function() {
    this.log("url %j", server.address());
  }.bind(this));

  var wsServer = new WebSocketServer({
    server: server
  });

  wsServer.on('connection', function(ws) {

    //this.ws = ws;

    ws.on('open', function open() { // no event ?
      debug("on.open");
    }.bind(this));

    ws.on('message', function message(data) {
      debug("on.message: %s %s", ws.upgradeReq.connection.remoteAddress, data);
      this.onMessage(data,ws);
    }.bind(this));

    ws.on('close', function close() {
      this.log("on.close client ip %s disconnected", ws.upgradeReq.connection.remoteAddress);
    }.bind(this));

    ws.on('error', function error(e) {
      this.log.error("on.error %s", e.message);
    }.bind(this))

    set_timeout = setTimeout(function() {
//      debug(this.ws);
      this.log("client ip %s connected", ws.upgradeReq.connection.remoteAddress);
      var msg = {
        "count": 0
      }
      ws.send(JSON.stringify(msg, null, 2));
    }.bind(this), 500);

  }.bind(this));

}

Websocket.prototype.onMessage = function(data,ws) {

  //this.log(ws);

  try {
    var msg = JSON.parse(data);

    if (!accessories[msg.Hostname])
    {
      addAccessory(msg,ws);
    } else {
      accessories[msg.Hostname].ws = ws;
    }
    sendEvent(null,msg);
  } catch (err) {
    this.log(err,msg);
    sendEvent(err);
  }

}
