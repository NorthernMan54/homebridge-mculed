--SAFETRIM

local module = {}

local mpu = require('mpu6050')
local ws
local duration = 5 -- minumum length of trigger event is 10 sec
local onStart
local offTimer = tmr.create()

function module.start(wsserver)
  package.loaded["accel"]=nil
  local tm = tmr.now()
  local last = 0
  local connected = false
  mpu.init()

  ws = websocket.createClient()
  ws:connect(wsserver)
  ws:on("connection", function(ws)
    print('got ws connection', ws)
    connected = true;
  end)
  ws:on("receive", function(sck, msg, opcode)
    --print('\ngot message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
    local json = require('json')
    local result = json.parse(msg)
    print('\ngot message:', result["count"], result["sensitivity"], opcode) -- opcode is 1 for text message, 2 for binary
    sck:send(mpu.read(), 1)
    if ( result["sensitivity"] ~= nil )
    then
      mpu.sensitivity(result["sensitivity"])
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

  function motionEvent(value, interval)
    -- Ignore sensor for first 30 seconds
    if tmr.time() > 30 then
      if value == last then
        print("Motion Event - False")
      else
        if connected == true then
          print("\nMotion Event", value, interval)
          if value then
            onStart = tmr.time() + duration
            print("Time", tmr.time(), onStart)
            offTimer:stop()
            ws:send(mpu.read(value, interval), 1)
          else
            local length = (onStart - tmr.time() ) * 1000
            if length < 999 then
              -- Duration has past
              print("Send Immediate off", tmr.time(), onStart)
              ws:send(mpu.read(value, interval), 1)
            else
              -- Need to wait for duration to pass before sending off
              print("Start Delayed Off", (onStart - tmr.time() ), tmr.time())
              offTimer:alarm(length, tmr.ALARM_SINGLE, function()
                print("Sent delayed off", tmr.time())
                ws:send(mpu.read(value, interval), 1)
              end)
            end
          end
        else
          print( "Motion event not sent, no connection")
        end
      end
    else
      print( "\nMotion Event - Ignored, sensor warming up")
    end
    last = value
  end

  local movementA, movementG, Temperature = 0, 0, 0
  local interval = tmr.time()

  tmr.create():alarm(500, tmr.ALARM_AUTO, function()

    local movementA, movementG, trigger, status, Temperature = mpu.rawRead()

    if ( trigger )
    then
      motionEvent(status, tmr.time() - interval)
      interval = tmr.time()
      if status then
        led.flashRed()
      end
    end
    --else
    --end
  end)

  print("Acceleration Sensor Enabled")
end

return module
