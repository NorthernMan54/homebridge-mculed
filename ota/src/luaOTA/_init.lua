--SAFETRIM
-- function _init(self, args)
local self, args = ...

-- The config is read from config.json but can be overridden by explicitly
-- setting the following args.  Setting to "nil" deletes the config arg.
--
--    ssid, spwd                Credentials for the WiFi
--    server, port, secret      Provisioning server:port and signature secret
--    leave                     If true then the Wifi is left connected
--    espip, gw, nm, nsserver   These need set if you are not using DHCP

local wifi, file, json, tmr = wifi, file, sjson, tmr
local log, sta, config = self.log, wifi.sta, nil

local function _wifiConnect(availableAccessPoints)
  local passwords = require(self.prefix.."passwords")
  package.loaded[self.prefix.."passwords"] = nil
  if availableAccessPoints then
    local found = 0
    for key, value in pairs(availableAccessPoints) do
      if passwords.SSID and passwords.SSID[key] then
        sta.config(passwords.SSID[key])
        sta.connect()
        print("Connecting to " .. key .. " ...")
        found = 1
      end
    end
    passwords = nil
    if found == 0 then
      print("Error finding AP")
      --led.error(1)
    end
  else
    print("Error getting AP list")
    --led.error(2)
  end
  _wifiConnect = nil
end

print ("\nStarting Provision Checks")
log("Starting Heap:", node.heap())

if file.open(self.prefix .. "config.json", "r") then
  local s; s, config = pcall(json.decode, file.read())
  if not s then print("Invalid configuration:", config) end
  file.close()
end
if type(config) ~= "table" then config = {} end

for k, v in pairs(args or {}) do config[k] = (v ~= "nil" and v) end

wifi.sta.clearconfig()
log("Mode is", wifi.setmode(wifi.STATION, false))
config.id = wifi.sta.gethostname()
config.a = "HI"

self.config = config
self.secret = config.secret
config.secret = nil

log("Config is:", json.encode(self.config))

sta.getap(0, _wifiConnect)

package.loaded[self.modname] = nil
self.modname = nil
log("pre: _doTick", node.heap())
tmr.alarm(0, 500, tmr.ALARM_AUTO, self:_doTick())
-- end
