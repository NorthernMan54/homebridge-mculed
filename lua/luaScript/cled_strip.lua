--SAFETRIM

local module = {}

local strip_buffer = ws2812.newBuffer(24, 3)

local state = { Hue = 0, Saturation = 0, ColorTemperature = 140; pwm = true, Brightness = 20, On = false }
local changeTimer = tmr.create()
local disableLedTimer = tmr.create()

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

  local tp = 255 * 3 / ( r + g + b )

  if tp > 1 then tp = 1 end

  return math.floor(r * tp * l1 / 100), math.floor(g * tp * l1 / 100), math.floor(b * tp * l1 / 100)
end

disableLedTimer:register(500, tmr.ALARM_SEMI, function()
  local pin = 4
  --print("disable led")
  ws2812_effects.stop()
  --gpio.mode(pin, gpio.OUTPUT)
  --gpio.write(pin, gpio.HIGH)
end)

local function on(value)
  if value == true and state.On == true and state.pwm == false then
    ws2812_effects.stop()
    ws2812_effects.set_speed(100)
    ws2812_effects.set_delay(100)
    ws2812_effects.set_brightness(255)
    ws2812_effects.set_color(hslToRgb(state.Hue, state.Saturation, state.Brightness))
    ws2812_effects.set_mode("static")
    ws2812_effects.start()
    print("Turning on RGB LED", hslToRgb(state.Hue, state.Saturation, state.Brightness), strip_buffer:power())
    print("Turn off PWM mode")
    pwm.setup(config.pwm, 480, 0)
    pwm.start(config.pwm)
  elseif value == true and state.On == true and state.pwm == true then
    print("Turning on White PWM LED", state.Brightness)
    pwm.setup(config.pwm, 480, state.Brightness * 10)
    pwm.start(config.pwm)
    print("Turning off RGB LED")
    ws2812_effects.stop()
    ws2812_effects.set_speed(100)
    ws2812_effects.set_delay(100)
    ws2812_effects.set_brightness(0)
    ws2812_effects.set_color(0, 0, 0)
    ws2812_effects.set_mode("static")
    ws2812_effects.start()
  else
    print("Turning off RGB LED")
    ws2812_effects.stop()
    ws2812_effects.set_speed(100)
    ws2812_effects.set_delay(100)
    ws2812_effects.set_brightness(0)
    ws2812_effects.set_color(0, 0, 0)
    ws2812_effects.set_mode("static")
    ws2812_effects.start()
    disableLedTimer:start()
    print("Turn off PWM mode")
    pwm.setup(config.pwm, 480, 0)
    pwm.start(config.pwm)
  end
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

-- Set effect mode and parameter

function module.setMode(value,param)
  state.pwm = true;
  state.Hue = 0;
  state.Saturation = 0;
  state.ColorTemperature = value;
  changeTimer:start()
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
