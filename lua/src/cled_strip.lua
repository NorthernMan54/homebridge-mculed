--SAFETRIM

local module = {}

local strip_buffer = ws2812.newBuffer(24, 3)

local state = { Hue = 0, Saturation = 0, ColorTemperature = 140; pwm = true, Brightness = 20, On = false }
local changeTimer = tmr.create()
local disableLedTimer = tmr.create()
local effectsTimer = tmr.create()

-- Borrowed from https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua

local function hslToRgb(h1, s1, l1)
  -- print("h1,s1,l1", h1, s1, l1)
  local g,r,b = color_utils.hsv2grb(h1, s1 * 2.55, l1 * 2.55)
return {r,g,b}

end

disableLedTimer:register(500, tmr.ALARM_SEMI, function()
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

local function rgbControl(speed, delay, brightness, color, mode)
  -- print("Color", unpack(color))
  ws2812_effects.set_speed(speed)
  ws2812_effects.set_delay(delay)
  ws2812_effects.set_brightness(brightness)
  ws2812_effects.set_color(unpack(color))
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
    disableLedTimer:start()
    -- print("Turn off PWM mode")
    rgbControl(100, 100, 0, hslToRgb(0, 0, 0), "static")
    pwmControl(0)
    effectsTimer:stop()
  end
  ws2812_effects.start()
end

changeTimer:register(150, tmr.ALARM_SEMI, function() on(true) end)

function module.setHue(value)
  state.Hue = value;
  state.pwm = false;
  state.ColorTemperature = 0;
  changeTimer:start()
end

function module.setOn(value)
  state.On = value;
  state.pwm = true;
  state.Hue = 0;
  state.Saturation = 0;
  state.ColorTemperature = 140;
  changeTimer:start()
end

function module.setSaturation(value)
  state.Saturation = value;
  state.pwm = false;
  state.ColorTemperature = 0;
  changeTimer:start()
end

function module.setBrightness(value)
  state.Brightness = value;
  changeTimer:start()
end

-- Colour temperature just turns on LED's

function module.setCT(value)
  state.pwm = true;
  state.Hue = 0;
  state.Saturation = 0;
  state.ColorTemperature = value;
  changeTimer:start()
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
  changeTimer:start()
end

local function colorGrad(value)
  local hue = value * 120 % 360
  return string.char(unpack(hslToRgb(hue, 100, 100)))
end
-- Set effect mode and parameter
function module.setMode(mode, param)
  state = { Hue = 0, Saturation = 100, ColorTemperature = 0; pwm = false, Brightness = 100, On = true }
  -- print("Turning on RGB LED", hslToRgb(state.Hue, state.Saturation, state.Brightness), strip_buffer:power())
  -- print("Turn off PWM mode") 
  pwmControl(0)
  ws2812_effects.stop()
  if mode == "fade" then
    effectsTimer:register(param, tmr.ALARM_AUTO, function()
      state.Hue = state.Hue + 1
      if state.Hue > 359 then
        state.Hue = 0
      end
      rgbControl(100, 100, 255, hslToRgb(state.Hue, state.Saturation, state.Brightness), "static")
      ws2812_effects.start()
    end)
    effectsTimer:start()
  elseif mode == "shift" then
    for i = 1, 24 do
      strip_buffer:set(i, colorGrad(i))
    end
    ws2812.write(strip_buffer)
    effectsTimer:register(param, tmr.ALARM_AUTO, function()
      strip_buffer:shift(1, ws2812.SHIFT_CIRCULAR)
      ws2812.write(strip_buffer)
    end)
    effectsTimer:start()
  else

  end
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
  changeTimer:start()
end

-- Module init

function module.init(wsserver)
  ws2812.init()
  ws2812_effects.init(strip_buffer)
  on(false)
end

return module
