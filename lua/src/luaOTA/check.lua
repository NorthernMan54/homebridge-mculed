--SAFETRIM
--------------------------------------------------------------------------------
-- LuaOTA provisioning system for ESPs using NodeMCU Lua
-- LICENCE: http://opensource.org/licenses/MIT
-- TerryE  15 Jul 2017
--
-- See luaOTA.md for description and implementation notes

--------------------------------------------------------------------------------

-- upvals
local crypto, file, json, net, node, table, tmr, wifi =
crypto, file, sjson, net, node, table, tmr, wifi
local error, pcall = error, pcall
local loadfile, gc = loadfile, collectgarbage
local concat, unpack = table.concat, unpack or table.unpack

local self = {post = node.task.post, prefix = "luaOTA/", conf = {}}

self.log = (DEBUG == true) and print or function() end
local log = self.log
self.modname = ...

--------------------------------------------------------------------------------------
-- Utility Functions

setmetatable( self, {__index = function(self, func) --upval: loadfile
  -- The only __index calls in in LuaOTA are dynamically loaded functions.
  -- The convention is that functions starting with "_" are treated as
  -- call-once / ephemeral; the rest are registered in self
  func = self.prefix .. func
  --log("pre: loadfile", func, node.heap())
  local f, msg = loadfile( func..".lc")
  if msg then f, msg = loadfile(func..".lua") end
  --log("post: loadfile", func, node.heap())
  if msg then error (msg, 2) end
  if func:sub(8, 8) ~= "_" then self[func] = f end
  return f
end} )

function self.sign(arg) --upval: crypto, json, self
  arg = json.encode(arg)
  return arg .. crypto.toHex(crypto.hmac("MD5", arg, self.secret):sub(-3)) .. '\n'
end

function self.startApp(arg) --upval: gc, self, tmr, wifi
  package.loaded["luaOTA.check"]=nil
  gc();gc()
  tmr.unregister(0)
  self.socket = nil
  if not self.config.leave then wifi.setmode(wifi.NULLMODE, false) end
  local appMod = self.config.app or "luaOTA.default"
  local appMethod = self.config.entry or "entry"
  if not arg then arg = "General timeout on provisioning" end
  self.post(function() --upval: appMod, appMethod, arg
    log("pre: post", node.heap())
    self = nil
    --print("arg",arg)
    tmr.create():alarm(2000, tmr.ALARM_SINGLE, function()
      print("Running program",appMod,appMethod)
      log("pre: require", node.heap())
      require(appMod)[appMethod](arg)
    end)
  end)
end

function self.socket_send(socket, rec, opt_buffer)
return socket:send(self.sign(rec) .. (opt_buffer or ''))
end

--turn off leds
--function o()
--  ws2812.init()
--  local sb = ws2812.newBuffer(24, 3)
--  sb:fill(0, 0, 0)
--  ws2812.write(sb)
--  sb=nil
--end

self.post(function() -- upval: self
-- This config check is to prevent a double execution if the
-- user invokes with "require 'luaOTA/check':_init( etc>)" form
log("pre: _init", node.heap())
package.loaded["init"]=nil
--pcall(o)
package.loaded["luaOTA.check"]=nil
if not rawget(self, "config") then self:_init() end
end)

return self
