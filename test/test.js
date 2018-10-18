const WebSocket = require('ws');

const ws = new WebSocket('ws://node-ac5812');

ws.on('open', function open() {
  const array = new Float32Array(5);

  for (var i = 0; i < array.length; ++i) {
    array[i] = i / 2;
  }

  function intervalFunc() {

    ws.send("ls");
  }

  setInterval(intervalFunc, 1500);

});

ws.on('message', function incoming(data) {
  console.log(data.toString());
});
