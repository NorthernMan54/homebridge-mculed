--SAFETRIM

local module = {}

local currentMonitor = tmr.create()
local currentRead = tmr.create()
local current = 0
local reads = 0
local lcurrent = -999

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

    print("Current Sensor Enabled")
  end)
  ws:on("receive", function(sck, msg, opcode)
    print('got message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
    local sensors = require('sensors')
    sck:send(sensors.read(), 1)
  end)
  ws:on("close", function(_, status)
    print('connection closed', status)
    connected = false
    -- Reboot if connection lost
    node.restart()
  end)

  currentRead:register( 1, tmr.ALARM_AUTO, function(t)
    local _current = math.abs(adc.read(0) - 533)
    --uart.write(0, tostring(_current))
    --uart.write(0, " ")
    if _current > current then
      current = _current
    end
    reads = reads + 1
    if reads > 640 then
      --print()
      --print("last result", current, node.heap())
      reads = 0
      currentRead:stop()

      if math.abs( current - lcurrent) > 5 then
        print("Current changed", current, node.heap())
        lcurrent = current
        local sensors = require('sensors')
        ws:send(sensors.read(nil, nil, math.floor((lcurrent / 51.2 )*10+.5)/10), 1)
      end
      current = 0
    end
  end)

  currentMonitor:register( 1000, tmr.ALARM_AUTO, function(t)
    currentRead:start()
  end)


  currentMonitor:start()


end

return module
