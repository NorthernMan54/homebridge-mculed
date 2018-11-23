"use strict";

var request = require('requestretry');
var debug = require('debug')('xmas');

var pin = "031-45-154";
var seq = 0;

var device = {};

device[52] = {};
device[53] = {};
device[54] = {};

device[52].on = 9;
device[53].on = 9;
device[54].on = 10;

device[52].brightness = 10;
device[53].brightness = 10;
device[54].brightness = 13;

function generateBody(aid, hue) {
  // [{"aid":53,"iid":9,"value":1}, {"aid":53,"iid":11,"value":120}, {"aid":53,"iid":12,"value":100}, {"aid":53,"iid":10,"value":100}]
  // [{"aid":54,"iid":10,"value":1}, {"aid":54,"iid":11,"value":0}, {"aid":54,"iid":12,"value":100}, {"aid":54,"iid":13,"value":100}]

  var body = {
    "characteristics": [{
      "aid": aid,
      "iid": device[aid].on,
      "value": 1
    }, {
      "aid": aid,
      "iid": 11,
      "value": hue
    }, {
      "aid": aid,
      "iid": 12,
      "value": 100
    }, {
      "aid": aid,
      "iid": device[aid].brightness,
      "value": 100
    }]
  };
  return (JSON.stringify(body));
}

function HAPcontrol(host, port, body, callback) {
  debug("Calling http://%s:%s ", host, port, body);
  request({
    method: 'PUT',
    url: 'http://' + host + ':' + port + '/characteristics',
    timeout: 7000,
    maxAttempts: 1, // (default) try 5 times
    headers: {
      "Content-Type": "Application/json",
      "authorization": pin,
      "connection": "keep-alive"
    },
    body: body
  }, function(err, response) {
    // Response s/b 200 OK

    if (err) {
      debug("Homebridge Control failed %s:%s", host, port, body, err);
      if (callback) callback(err);
    } else if (response.statusCode !== 207) {
      if (response.statusCode === 401) {
        debug("Homebridge auth failed, invalid PIN %s %s:%s", pin, host, port, body, err, response.body);
        if (callback) callback(new Error("Homebridge auth failed, invalid PIN " + pin));
      } else {
        debug("Homebridge Control failed %s:%s Status: %s ", host, port, response.statusCode, body, err, response.body);
        if (callback) callback(new Error("Homebridge control failed"));
      }
    } else {
      var rsp;

      try {
        rsp = JSON.parse(response.body);
      } catch (ex) {
        console.error("Homebridge Response Failed %s:%s", host, port, response.statusCode, response.statusMessage);
        console.error("Homebridge Response Failed %s:%s", host, port, response.body, ex);

        if (callback) callback(new Error(ex));
      }
      if (callback) callback(null, rsp);
    }
  });
}

function colorSeq(seq) {
  // 0,0,0,120,120,120,240,240,240

  debug(Math.floor(seq / 3) * 120);
  return Math.floor(seq / 3) * 120;
}

function intervalFunc() {
  seq = seq + 1;
  if (seq > 8) seq = 0;
  HAPcontrol("leonard", 51827, generateBody(53, colorSeq(seq + 0)));
  HAPcontrol("leonard", 51827, generateBody(52, colorSeq(seq + 1)));
  HAPcontrol("leonard", 51827, generateBody(54, colorSeq(seq + 2)));
}

setInterval(intervalFunc, 1000);
