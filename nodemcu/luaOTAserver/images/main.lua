--SAFETRIM

local lua_mdns = nil

local function start()
  dofile("websocket.lc")
  websocket.createServer(80, function (socket)
    local data
    --  node.output(function (msg)
    --    return socket.send(msg, 1)
    --  end, 1)
    print("New websocket client connected")

    function socket.onmessage(payload, opcode)
      print("message",payload,opcode)
      local s; s, cmd = pcall(sjson.decode, payload)
      print("decoded",cmd)
      if opcode == 1 then
        if payload == "ls" then
          local list = file.list()
          local lines = {}
          for k, v in pairs(list) do
            lines[#lines + 1] = k .. "\0" .. v
          end
          socket.send(table.concat(lines, "\0"), 2)
          return
        end
        local command, name = payload:match("^([a-z]+):(.*)$")
        if command == "load" then
          file.open(name, "r")
          socket.send(file.read(), 2)
          file.close()
        elseif command == "save" then
          file.open(name, "w")
          file.write(data)
          data = nil
          file.close()
        elseif command == "compile" then
          node.compile(name)
        elseif command == "run" then
          dofile(name)
        elseif command == "eval" then
          local fn, success, err
          fn, err = loadstring(data, name)
          if not fn then
            fn = loadstring("print(" .. data .. ")", name)
          end
          data = nil
          if fn then
            success, err = pcall(fn)
          end
          if not success then
            print(err)
          end
        else
          print("Invalid command: " .. command)
        end
      elseif opcode == 2 then
        data = payload
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
  mdns.register(config.mdnsName)
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
