local module = {}
local ws
local duration = 5 -- minumum length of trigger event is 10 sec
local onStart = tmr.time()
local offTimer = tmr.create()
local buttonPress = tmr.time()
local oldDoorState = 1

local function readSensor()

  -- Characteristic.CurrentDoorState.OPEN = 0;
  -- Characteristic.CurrentDoorState.CLOSED = 1;
  -- Characteristic.CurrentDoorState.OPENING = 2;
  -- Characteristic.CurrentDoorState.CLOSING = 3;
  -- Characteristic.CurrentDoorState.STOPPED = 4;

  local opened = gpio.read(config.gdopened)
  local closed = gpio.read(config.gdclosed)
  print("Opened, Closed", opened, closed )
  oldDoorState = CurrentDoorState
  if ( opened == 1 and closed == 0 ) then
    CurrentDoorState = 1  -- Closed
  elseif ( opened == 0 and closed == 1 ) then
    CurrentDoorState = 0  -- Open
  elseif ( opened == 1 and closed == 1 ) then
    if ( oldDoorState == 0 or oldDoorState == 3 ) then
      CurrentDoorState = 3
    elseif ( oldDoorState == 1 or oldDoorState == 2 ) then
      CurrentDoorState = 2
    else
      CurrentDoorState = 4
    end
  else
    -- door is unknown
    CurrentDoorState = 4
  end
  print("CurrentDoorState", CurrentDoorState)
end

function module.start(wsserver)
  gpio.mode(config.gdrelay, gpio.OUTPUT)
  gpio.mode(config.gdopened, gpio.INT, gpio.PULLUP)
  gpio.mode(config.gdclosed, gpio.INT, gpio.PULLUP)
  local tm = tmr.now()
  local last = 0
  local connected = false;

  ws = websocket.createClient()
  ws:connect(wsserver)
  ws:on("connection", function(ws)
    print('got ws connection', ws)
    connected = true;
  end)
  ws:on("receive", function(sck, msg, opcode)
    local json = require("json")
    local result = json.parse(msg)
    collectgarbage()
    print('\ngot message:', result["count"], result["sensitivity"], opcode) -- opcode is 1 for text message, 2 for binary

    if ( result["sensitivity"] ~= nil )
    then
      --mpu.sensitivity(result["sensitivity"])
    end
    if ( result["duration"] ~= nil )
    then
      duration = result["duration"]
    end

    if ( result["button"] ~= nil )
    then
      local button = result["button"]
      buttonPress = tmr.time()
      gpio.write(config.gdrelay, gpio.HIGH)
      local buttonTimer = tmr.create()
      buttonTimer:alarm(button, tmr.ALARM_SINGLE, function()
        gpio.write(config.gdrelay, gpio.LOW)
      end)
    else
      local sensors = require("sensors")
      sck:send(sensors.read(readSensor()), 1)
      collectgarbage()
    end

    tmr.softwd(600)
  end)
  ws:on("close", function(_, status)
    print('connection closed', status)
    connected = false;
    -- Reboot if connection lost
    node.restart()

  end)

  function motionEvent(value)

    print("Door event")
    local sensors = require("sensors")
    ws:send(sensors.read(readSensor()), 1)

  end

  gpio.trig(config.gdopened, "both", motionEvent)
  gpio.trig(config.gdclosed, "both", motionEvent)
  print("Motion Sensor Enabled")
end

return module
