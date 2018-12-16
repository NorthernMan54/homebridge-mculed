--SAFETRIM

local module = {}

local sb = ws2812.newBuffer(24, 3)
local state = { Hue = 0, sat = 0, cTemp = 140; pwm = true, Brightness = 20, On = false }
local cTim = tmr.create()
local dlTim = tmr.create()
local eTim = tmr.create()
-- local hsv = require('hsx')

-- local function hslToRgb(h1, s1, l1)
--  local g, r, b = color_utils.hsv2grb(h1, s1 * 2.55, l1 * 2.55)
--  print("setting",r,g,b)
--  return r, g, b
-- end

-- Borrowed from https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua

local function hslToRgb(h1, s1, l1)
  local r, g, b

  local h, s, l = h1 / 360, s1 / 100, l1 / 100 * .5

  if s == 0 then
    r, g, b = 255, 255, 255 -- achromatic
  else
    local function hue2rgb(p, q, t)
      if t < 0 then t = t + 1 end
      if t > 1 then t = t - 1 end
      if t < 1 / 6 then return p + (q - p) * 6 * t end
      if t < 1 / 2 then return q end
      if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
      return p
    end

    local q
    if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
    local p = 2 * l - q

    r = hue2rgb(p, q, h + 1 / 3) * 255
    g = hue2rgb(p, q, h) * 255
    b = hue2rgb(p, q, h - 1 / 3) * 255
  end

  -- Power limiter, not used

  local tp = 255 * 1 / ( r + g + b )

  if tp > 1 then tp = 1 end

  return math.floor(r * tp * l1 / 100), math.floor(g * tp * l1 / 100), math.floor(b * tp * l1 / 100)
end


-- local function rgb2hsv( r, g, b )
--  local min, max, abs = math.min, math.max, math.abs
--  local M, m = max( r, g, b ), min( r, g, b )
--  local C = M - m
--  local K = 1.0 / (6.0 * C)
--  local h = 0.0
--  if C ~= 0.0 then
--    if M == r then h = ((g - b) * K) % 1.0
--    elseif M == g then h = (b - r) * K + 1.0 / 3.0
--    else h = (r - g) * K + 2.0 / 3.0
--    end
--  end
--  -- Hue should be in degrees
--  h = math.floor(h * 360 + .5)
--  return h, M == 0.0 and 0.0 or C / M, M
-- end

function rgb2hsl( r, g, b )
  local min, max, abs = math.min, math.max, math.abs
  local M, m = max( r, g, b ), min( r, g, b )
  local C = M - m
  local K = 1.0 / (6 * C)
  local h = 0
  if C ~= 0 then
    if M == r then h = ((g - b) * K) % 1.0
    elseif M == g then h = (b - r) * K + 1.0 / 3.0
    else h = (r - g) * K + 2.0 / 3.0
    end
  end
  local l = 0.5 * (M + m)
  local s = 0
  if l > 0 and l < 1 then
    s = C / (1 - abs(l + l - 1))
  end
  h = math.floor(h * 360 + .5)
  return h, s, l
end

dlTim:register(500, tmr.ALARM_SEMI, function()
  local pin = 4
  ws2812_effects.stop()
end)

local function pwmControl(value)
  pwm.setup(config.pwm, 480, value)
  pwm.start(config.pwm)
end

local function rgbControl(speed, delay, brightness, color, mode)
  ws2812_effects.set_speed(speed)
  ws2812_effects.set_delay(delay)
  ws2812_effects.set_brightness(brightness)
  ws2812_effects.set_color(unpack(color))
  ws2812_effects.set_mode(mode)
end

local function on(value)
  ws2812_effects.stop()
  if value == true and state.On == true and state.pwm == false then
    -- print("hslToRgb",hslToRgb(state.Hue, state.sat, state.Brightness))
    rgbControl(100, 100, 255, {hslToRgb(state.Hue, state.sat, state.Brightness)}, "static")
    pwmControl(0)
  elseif value == true and state.On == true and state.pwm == true then
    -- print("Turning on White PWM LED", state.Brightness)
    -- print("hslToRgb",hslToRgb(state.Hue, state.sat, state.Brightness))
    pwmControl(state.Brightness * 10)
    rgbControl(100, 100, 0, {hslToRgb(0, 0, 0)}, "static")
  else
    -- print("Turning off RGB LED")
    dlTim:start()
    -- print("Turn off PWM mode")
    rgbControl(100, 100, 0, {hslToRgb(0, 0, 0)}, "static")
    pwmControl(0)
    eTim:stop()
  end
  ws2812_effects.start()
end

cTim:register(150, tmr.ALARM_SEMI, function() on(true) end)

function module.setHue(value)
  state.Hue = value;
  state.pwm = false;
  state.cTemp = 0;
  cTim:start()
end

function module.setOn(value)
  state.On = value;
  state.pwm = true;
  state.Hue = 0;
  state.sat = 0;
  state.cTemp = 140;
  cTim:start()
end

function module.setSaturation(value)
  state.sat = value;
  state.pwm = false;
  state.cTemp = 0;
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
  state.sat = 0;
  state.cTemp = value;
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
    state = { Hue = 0, sat = 0, cTemp = 140; pwm = true, Brightness = 100, On = true }
  end
  cTim:start()
end

-- slide colors across the whole strip

local function slide()
  eTim:register(1500, tmr.ALARM_AUTO, function()
    for i = 1, 24 do
    -- print("LED", i, sb:get(i))
    local hue, s, l = rgb2hsl(sb:get(i))
    -- print("Hue", i, hue, s, l)
    hue = hue + 2
    if hue > 359 then
      hue = 0
    end
    -- print("New", i, hslToRgb(hue, 100, 100))
    sb:set(i, hslToRgb(hue, 100, 100))
  end
  ws2812.write(sb)
end)
end

-- Set effect mode and parameter

function module.setMode(mode, param)
state = { Hue = 0, sat = 100, cTemp = 0; pwm = false, Brightness = 100, On = true }
-- print("Turning on RGB LED", hslToRgb(state.Hue, state.Saturation, state.Brightness), sb:power())
-- print("Turn off PWM mode")
pwmControl(0)
ws2812_effects.stop()
if mode == "fade" then
  -- Full strip slowly fades across all colors
  eTim:register(param, tmr.ALARM_AUTO, function()
    state.Hue = state.Hue + 1
    if state.Hue > 239 then
      state.Hue = 0
    end
    rgbControl(100, 100, 255, {hslToRgb(state.Hue, state.sat, state.Brightness)}, "static")
    ws2812_effects.start()
  end)
elseif mode == "shift" then
  -- Each section rotates thru the RGB
  for i = 1, 24 do
    sb:set(i, hslToRgb(i * 120 % 240, 100, 100))
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
  slide()
elseif mode == "slip" then
  -- Slip the whole strip thru the color spectrum
  for i = 1, 24 do
    sb:set(i, hslToRgb(i * 5, 100, 100))
  end
  slide()
end
eTim:start()
end

-- Button press / power toggle

function module.colorButton()
if state.On then
  state = { Hue = state.Hue + 360 / 12, sat = 100, cTemp = 0; pwm = false, Brightness = state.Brightness, On = true }
  if state.Hue > 359 then
    state.Hue = 0
  end
else
  state = { Hue = 0, sat = 100, cTemp = 0; pwm = false, Brightness = 100, On = true }
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
