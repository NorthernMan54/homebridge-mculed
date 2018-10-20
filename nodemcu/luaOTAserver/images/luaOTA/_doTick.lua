tmr.stop(0)--SAFETRIM
-- function _doTick(self)

-- Upvals
local self = ...
local wifi, net = wifi, net
local sta = wifi.sta
local config, log, startApp = self.config, self.log, self.startApp
local tick_count = 0
local lua_mdns
local gc=collectgarbage

local function socket_close(socket) --upval: self, startApp
  if rawget(self, "socket") then
    self.socket = nil -- remove circular reference in upval
    pcall(socket.close, socket)
    return startApp("Unexpected socket close")
  end
end

local function receiveFirstRec(socket, rec) -- upval: self, crypto, startApp, tmr
  local cmdlen = (rec:find('\n', 1, true) or 0) - 1
  local cmd, hash = rec:sub(1, cmdlen - 6), rec:sub(cmdlen - 5, cmdlen)
  gpio.write(0, gpio.HIGH)
  if cmd:find('"r":"OK!"', 1, true) or cmdlen < 16 or
  hash ~= crypto.toHex(crypto.hmac("MD5", cmd, self.secret):sub(-3)) then
    print "No provisioning changes required"
    self.socket = nil
    self.post(function() --upval: socket
      if socket then pcall(socket.close, socket) end
    end)
    pcall(conn.close, conn)
    conn = nil
    log("pre: startApp", node.heap())
    return startApp("OK! No further updates needed")
  end
  -- Else a valid request has been received from the provision service free up
  -- some resources that are no longer needed and set backstop timer for general
  -- timeout.  This also dereferences the previous doTick cb so it can now be GCed.
  gc()
  tmr.alarm(0, 30000, tmr.ALARM_SINGLE, self.startApp)
  log("pre: _provision", node.heap())
  return self:_provision(socket, rec)
end

local function socket_connect(socket) --upval: self, socket_connect
  print "Connected to provisioning service"
  self.socket = socket
  socket_connect = nil -- make this function available for GC
  socket:on("receive", receiveFirstRec)
  return self.socket_send(socket, self.config)
end

local function hb_found(ws)
  lua_mdns = nil
  hb_found = nil
  log("Found provioning server",ws.ipv4,ws.port)
  conn = net.createConnection(net.TCP, 0)
  conn:on("connection", socket_connect)
  conn:on("disconnection", socket_close)
  conn:connect(ws.port, ws.ipv4)
end

local conn
gpio.mode(0, gpio.OUTPUT)
-- GPIO 4 is used with ws2812 light strips
--gpio.mode(4, gpio.OUTPUT)
--gpio.write(4, gpio.HIGH)
return function() -- the proper doTick() timer callback
  tick_count = tick_count + 1
  if ( tick_count % 2 == 0 ) then
    gpio.write(0, gpio.HIGH)
  else
    gpio.write(0, gpio.LOW)
  end
  --log("entering tick", tick_count, sta.getconfig(false), sta.getip())
  if (tick_count < 20) then -- (wait up to 10 secs for Wifi connection)
    local status, ip = sta.status(), {sta.getip()}
    if (status == wifi.STA_GOTIP) then
      log("Connected:", unpack(ip))
      if (config.nsserver) then
        net.dns.setdnsserver(config.nsserver, 0)
      end
      gc(); gc()
      log("pre: _mdns", node.heap())
      lua_mdns = require("luaOTA/_mdns")
      lua_mdns.mdns_query("_"..config.server.."._tcp", hb_found)

      tick_count = 20
    end

  elseif (tick_count == 20) then -- assume timeout and exec app CB
    return self.startApp("OK: Timeout on waiting for wifi station setup")

  elseif (tick_count == 36) then -- wait up to 2.5 secs for TCP response
    gpio.write(0, gpio.HIGH)
    tmr.unregister(0)
    if ( conn ~= nil ) then
      print("Closing socket")
      pcall(conn.close, conn)
    end
    self.socket = nil
    return startApp("OK: Timeout on waiting for provision service response")
  end
end
-- end
