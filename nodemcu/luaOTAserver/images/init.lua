--SAFETRIM

print("Last failure", node.bootreason());
DEBUG = false
tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()
  -- turn off led strip
  ws2812.init(ws2812.MODE_SINGLE)
  ws2812.write(string.char(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
  pwm.setup(2,480,50)
  pwm.start(2)
  require "luaOTA.check"
end)
