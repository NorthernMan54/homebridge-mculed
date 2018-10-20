const WebSocket = require('ws');

const ws = new WebSocket('ws://node-ac5812');

ws.on('open', function open() {
  const array = new Float32Array(5);

  for (var i = 0; i < array.length; ++i) {
    array[i] = i / 2;
  }

  var value = true;

  function intervalFunc() {
    ws.send('{ "cmd": "set", "func": "on", "value": ' + value + ' }');
    console.log("Sending",value);
    if (value) {
      value = false;
    } else {
      value = true;
    }
  }

  setInterval(intervalFunc, 5000);

});

ws.on('message', function incoming(data) {
  console.log(data.toString());
});
