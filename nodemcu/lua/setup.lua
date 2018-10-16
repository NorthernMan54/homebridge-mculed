local module = {}

local function wifi_start(list_aps)
  local passwords = require("passwords")
  if list_aps then
    local found = 0
    for key,value in pairs(list_aps) do
      if passwords.SSID and passwords.SSID[key] then
        wifi.sta.config(passwords.SSID[key])
        wifi.sta.connect()
        print("Connecting to " .. key .. " ...")
        found = 1
      end
    end
    if found == 0 then
      print("Error finding AP")
      led.error(1)
    end
  else
    print("Error getting AP list")
    led.error(2)
  end
end

function module.start(wifi_ready)
  package.loaded[module]=nil
  print("Configuring Wifi ...")
  wifi.setmode(wifi.STATION)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,wifi_ready)
  wifi.sta.getap(0,wifi_start)
end

return module
