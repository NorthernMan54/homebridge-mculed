local module = {}
local ws
local duration = 5 -- minumum length of trigger event is 10 sec
local onStart
local offTimer = tmr.create()

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
  local connected = false;

  ws = websocket.createClient()
  ws:connect(wsserver)
  ws:on("connection", function(ws)
    print('got ws connection', ws)
    connected = true;
  end)
  ws:on("receive", function(sck, msg, opcode)
    local json = require('json')
    local result = json.parse(msg)
    print('\ngot message:', result["count"], result["sensitivity"], opcode) -- opcode is 1 for text message, 2 for binary
    local sensors = require('sensors')
    sck:send(sensors.read(readSensor()), 1)
    if ( result["sensitivity"] ~= nil )
    then
      --mpu.sensitivity(result["sensitivity"])
    end
    if ( result["duration"] ~= nil )
    then
      duration = result["duration"]
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
    -- Ignore sensor for 10 seconds
    if tmr.time() > 30 then
      if value == last then
        print("Motion Event - False")
      else
        if connected == true then
          print("Motion Event", value, math.floor((tmr.now() - tm) / 1000000 + 0.5))
          if value == 1 then
            onStart = tmr.time() + duration
            print("Time", tmr.time(), onStart)
            offTimer:stop()
            tm = tmr.now()
            local sensors = require('sensors')
            ws:send(sensors.read(value, 0), 1)
          else
            if onStart < tmr.time() then
              -- Duration has past
              print("Send Immediate off", tmr.time(), onStart)
              tm = tmr.now()
              local sensors = require('sensors')
              ws:send(sensors.read(value, 0), 1)
            else
              -- Need to wait for duration to pass before sending off
              print("Start Delayed Off", (onStart - tmr.time() ), tmr.time())
              offTimer:alarm((onStart - tmr.time() ) * 1000, tmr.ALARM_SINGLE, function()
                print("Sent delayed off", tmr.time())
                tm = tmr.now()
                local sensors = require('sensors')
                ws:send(sensors.read(value, 0), 1)
              end)
            end
          end
        else
          print( "Motion event not sent, no connection")
        end
      end
    else
      print( "Motion Event - Ignored, sensor warming up")
    end
    last = value
  end

  gpio.trig(config.SC501, "both", motionEvent)
  print("Motion Sensor Enabled")
end

return module
