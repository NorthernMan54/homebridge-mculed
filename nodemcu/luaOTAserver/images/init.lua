--SAFETRIM


print("Last failure", node.bootreason());
DEBUG = true
tmr.create():alarm(1000, tmr.ALARM_SINGLE, function()
  ws2812.init(ws2812.MODE_SINGLE)
  ws2812.write(string.char(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
  pwm.setup(2,480,50)
  pwm.start(2)
  require "luaOTA.check"
end)
