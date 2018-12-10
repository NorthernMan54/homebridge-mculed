--SAFETRIM

local mod

local function wifi_ready()
  print("\n====================================")
  print("Name is:         "..config.ID)
  print("ESP8266 mode is: " .. wifi.getmode())
  print("MAC address is: " .. wifi.ap.getmac())
  print("IP is "..wifi.sta.getip())
  print("====================================")
  -- setup = nil
  -- wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)

  tmr.softwd(600)
  -- led.connected()
  if string.find(config.Model, "CLED") then
    mod = require('led_strip')
  end
  package.loaded["main"] = nil
  print("Running " .. config.Model )
  mdns.register(config.ID, {service = config.mdnsName})
  mod.start()
end

return {entry = function(msg)
  -- Start of code, reboot if not connected within 60 seconds
  tmr.softwd(60)
  print("Starting mculed") -- 38984
  config = require("config-"..wifi.sta.gethostname())
  package.loaded["config-"..wifi.sta.gethostname()] = nil
  -- led = require("led")
  -- led.boot()
  wifi_ready()
end}
