--SAFETRIM

local module = {}

local sb = ws2812.newBuffer(24, 3)

local state = { Hue = 0, Saturation = 0, ColorTemperature = 140; pwm = true, Brightness = 20, On = false }
local cTim = tmr.create()
local dlTim = tmr.create()
local eTim = tmr.create()

-- Borrowed from https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua

local function hslToRgb(h1, s1, l1)
  -- print("h1,s1,l1", h1, s1, l1)
  local g, r, b = color_utils.hsv2grb(h1, s1 * 2.55, l1 * 2.55)
  print("HSL",r, g, b)
  return r, g, b
end

dlTim:register(500, tmr.ALARM_SEMI, function()
  local pin = 4
  -- print("disable led")
  ws2812_effects.stop()
  -- gpio.mode(pin, gpio.OUTPUT)
  -- gpio.write(pin, gpio.HIGH)
end)

local function pwmControl(value)
  pwm.setup(config.pwm, 480, value)
  pwm.start(config.pwm)
end

local function rgbControl(speed, delay, brightness, r,g,b, mode)
  print("Color", color)
  ws2812_effects.set_speed(speed)
  ws2812_effects.set_delay(delay)
  ws2812_effects.set_brightness(brightness)
  ws2812_effects.set_color(r,g,b)
  ws2812_effects.set_mode(mode)
end

local function on(value)
  ws2812_effects.stop()
  if value == true and state.On == true and state.pwm == false then
    -- print("hslToRgb",hslToRgb(state.Hue, state.Saturation, state.Brightness))
    rgbControl(100, 100, 255, hslToRgb(state.Hue, state.Saturation, state.Brightness), "static")
    pwmControl(0)
  elseif value == true and state.On == true and state.pwm == true then
    -- print("Turning on White PWM LED", state.Brightness)
    -- print("hslToRgb",hslToRgb(state.Hue, state.Saturation, state.Brightness))
    pwmControl(state.Brightness * 10)
    rgbControl(100, 100, 0, hslToRgb(0, 0, 0), "static")
  else
    -- print("Turning off RGB LED")
    dlTim:start()
    -- print("Turn off PWM mode")
    rgbControl(100, 100, 0, hslToRgb(0, 0, 0), "static")
    pwmControl(0)
    eTim:stop()
  end
  ws2812_effects.start()
end

cTim:register(150, tmr.ALARM_SEMI, function() on(true) end)

function module.setHue(value)
  state.Hue = value;
  state.pwm = false;
  state.ColorTemperature = 0;
  cTim:start()
end

function module.setOn(value)
  state.On = value;
  state.pwm = true;
  state.Hue = 0;
  state.Saturation = 0;
  state.ColorTemperature = 140;
  cTim:start()
end

function module.setSaturation(value)
  state.Saturation = value;
  state.pwm = false;
  state.ColorTemperature = 0;
  cTim:start()
end

function module.setBrightness(value)
  state.Brightness = value;
  cTim:start()
end

-- Colour temperature just turns on LED's

function module.setCT(value)
  state.pwm = true;
  state.Hue = 0;
  state.Saturation = 0;
  state.ColorTemperature = value;
  cTim:start()
end

function module.getStatus()
  return state
end

-- Button press / power toggle

function module.onButton()
  if state.On then
    state.On = false;
  else
    state = { Hue = 0, Saturation = 0, ColorTemperature = 140; pwm = true, Brightness = 100, On = true }
  end
  cTim:start()
end

-- Set effect mode and parameter
function module.setMode(mode, param)
  state = { Hue = 0, Saturation = 100, ColorTemperature = 0; pwm = false, Brightness = 100, On = true }
  -- print("Turning on RGB LED", hslToRgb(state.Hue, state.Saturation, state.Brightness), sb:power())
  -- print("Turn off PWM mode")
  pwmControl(0)
  ws2812_effects.stop()
  if mode == "fade" then
    -- Full strip slowly fades across all colors
    eTim:register(param, tmr.ALARM_AUTO, function()
      state.Hue = state.Hue + 1
      if state.Hue > 359 then
        state.Hue = 0
      end
      rgbControl(100, 100, 255, hslToRgb(state.Hue, state.Saturation, state.Brightness), "static")
      ws2812_effects.start()
    end)

  elseif mode == "shift" then
    -- Each section rotates thru the RGB
    for i = 1, 24 do
      sb:set(i, hslToRgb(i * 120 % 360, 100, 100))
    end
    -- ws2812.write(sb)
    eTim:register(param, tmr.ALARM_AUTO, function()
      sb:shift(1, ws2812.SHIFT_CIRCULAR)
      ws2812.write(sb)
    end)
  elseif mode == "slide" then
    -- Each section slides thru the RGB
    for i = 1, 24 do
      sb:set(i, hslToRgb(i * 120 % 360, 100, 100))
    end
    -- ws2812.write(sb)
    eTim:register(1000, tmr.ALARM_AUTO, function()
      for i = 1, 24 do
      local hsv = require('hsx')
      -- print("LED", i, sb:get(i))
      local hue = hsv.rgb2hsv(sb:get(i))
      -- print("Hue", i, hue)
      hue = hue + 1
      if hue > 359 then
        hue = 0
      end
      -- print("New", i, unpack(hslToRgb(hue, 100, 100)))
      sb:set(i, unpack(hslToRgb(hue, 100, 100)))
    end
    ws2812.write(sb)
  end)

end
eTim:start()
end

-- Button press / power toggle

function module.colorButton()
if state.On then
  state = { Hue = state.Hue + 360 / 12, Saturation = 100, ColorTemperature = 0; pwm = false, Brightness = state.Brightness, On = true }
  if state.Hue > 359 then
    state.Hue = 0
  end
else
  state = { Hue = 0, Saturation = 100, ColorTemperature = 0; pwm = false, Brightness = 100, On = true }
end
cTim:start()
end

-- Module init

function module.init(wsserver)
ws2812.init()
ws2812_effects.init(sb)
on(false)
end

return module
