local module = {}

local vibrationIdle = tmr.create()
local vibrationValue = 0

local function readSensor()
  local motion = gpio.read(config.SC501)
  local motionStatus = 0
  if tmr.time() < 1 then
    motionStatus = 1
  end
  return motion, motionStatus
end

function module.start(wsserver)
  gpio.mode(config.SC501, gpio.INT)
  local tm = tmr.now()
  local last = 0
  local connected = false

  ws = websocket.createClient()
  ws:connect(wsserver)
  ws:on("connection", function(ws)
    print('got ws connection', ws)
    connected = true;
    gpio.trig(config.SC501, "both", motionEvent)
    print("Vibration Sensor Enabled")
  end)
  ws:on("receive", function(sck, msg, opcode)
    print('got message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
    local sensors = require('sensors')
    sck:send(sensors.read(readSensor()), 1)
  end)
  ws:on("close", function(_, status)
    print('connection closed', status)
    connected = false
    -- Reboot if connection lost
    node.restart()

  end)


  function motionEvent(value)

    print(string.format("Heap Available: event %s:%d", node.heap(), value))
    vibrationIdle:stop()
    vibrationIdle:start()
    if vibrationValue == 0 then
      vibrationValue = 1
      print("Vibration Event - Started")
      local sensors = require('sensors')
      ws:send(sensors.read(vibrationValue, 0), 1)
    end

  end

  vibrationIdle:register( 3000, 1, function(t)
    print("Vibration Event - Stopped")
    vibrationValue = 0;
    vibrationIdle:stop()
    local sensors = require('sensors')
    ws:send(sensors.read(vibrationValue, 0), 1)
  end)


end

return module
