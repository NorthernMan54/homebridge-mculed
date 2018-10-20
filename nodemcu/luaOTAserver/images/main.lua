--SAFETRIM

local function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end


local function start()
  dofile("websocket.lc")
  websocket.createServer(80, function (socket)
    tmr.softwd(-1)
    local data
    --  node.output(function (msg)
    --    return socket.send(msg, 1)
    --  end, 1)
    print("New websocket client connected")

    function socket.onmessage(payload, opcode)
      print("message", payload, opcode)
      local s; s, cmd = pcall(sjson.decode, payload)
      print("decoded", dump(cmd))
      print("Command", cmd["cmd"])
      if cmd["cmd"] == "set" then
        if cmd["func"] == "on" then
          mod.on(cmd["value"])
        elseif cmd["func"] == "brightness" then
          mod.brightness(cmd["value"])
        elseif cmd["func"] == "hsv" then
          mod.setHSV(cmd["value"])
        else
          print("Unknown function", cmd["func"])
        end
      elseif cmd["cmd"] == "get" then
        local majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
        local response =
        "{ \"Hostname\": \""..config.ID.."\", \"Model\": \""..config.Model.."\", \"Version\": \""..config.Version..
        "\", \"Firmware\": \""..majorVer.."."..minorVer.."."..devVer.."\" }"
        print("Sending", response)
        socket.send(response)
      else
        print("Unknown command", cmd["cmd"])
      end
    end
  end)

end

local function wifi_ready()
  print("\n====================================")
  print("Name is:         "..config.ID)
  print("ESP8266 mode is: " .. wifi.getmode())
  print("MAC address is: " .. wifi.ap.getmac())
  print("IP is "..wifi.sta.getip())
  print("====================================")
  setup = nil
  wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)

  print("Heap Available: -mdns  " .. node.heap() ) -- 18720

  tmr.softwd(600)
  led.connected()
  if string.find(config.Model, "CLED") then
    mod = require('cled_strip')
  end
  package.loaded["main"] = nil
  print("Heap Available: personaility  " .. node.heap() )
  mod.start("null")
  mdns.register(config.ID, {service = config.mdnsName})
  start()
end

return {entry = function(msg)
  -- Start of code, reboot if not connected within 60 seconds
  tmr.softwd(60)
  print("Heap Available:  " .. node.heap()) -- 38984
  config = require("config-"..wifi.sta.gethostname())
  package.loaded["config-"..wifi.sta.gethostname()] = nil
  print("Heap Available: config " .. node.heap()) -- 37248 1500
  led = require("led")
  print("Heap Available: led " .. node.heap()) -- 34200 3000ß
  --local setup = require("setup")
  --collectgarbage()
  --print("Heap Available: setup " .. node.heap()) -- 23280 4000

  led.boot()
  wifi_ready()
end}
