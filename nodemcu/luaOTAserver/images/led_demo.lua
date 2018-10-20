--SAFETRIM

local module = {}

local strip_buffer = ws2812.newBuffer(24, 3)
local state = { hue = 360, saturation = 100, ct = true, value = 20, brightness = 20, on = false }
local changeTimer = tmr.create()

local count, colour = 0, 0

local function modes(mode)
  -- the fire modes overwrite set_color
  if mode == 0 then return "static"
  elseif mode == 1 then return "blink"
  elseif mode == 2 then return "random_color"
  elseif mode == 3 then return "rainbow"
  elseif mode == 4 then return "rainbow_cycle"
  elseif mode == 5 then return "flicker"
  elseif mode == 6 then return "halloween"
  elseif mode == 7 then return "circus_combustus"
  elseif mode == 8 then return "cycle", 1
  elseif mode == 9 then return "larson_scanner"
  elseif mode == 10 then return "color_wipe"
  elseif mode == 11 then return "random_dot"
  elseif mode == 12 then return "fire"
  elseif mode == 13 then return "fire_soft"
  elseif mode == 14 then return "fire_intense"
  end
  return "static"
end

local function colours(x)
  if x == 0 then return 255, 128, 128
  elseif x == 1 then return 128, 255, 128
  elseif x == 2 then return 128, 128, 255
  end
  return 255, 255, 255
end

local function setColours()

  ws2812_effects.stop()
  ws2812_effects.set_color(colours(colour))
  print("Changing colour", colours(colour))
  ws2812_effects.start()
  colour = colour + 1
  if colour > 3 then colour = 0
  end
end

local function setMode()
  ws2812_effects.stop()
  ws2812_effects.set_mode(modes(count))
  print("Changing mode", modes(count))
  ws2812_effects.start()
  count = count + 1
  if count > 14 then count = 0
    setColours()
  end
end

local function demo()
  print("Running LED Strip")
  -- init the ws2812 module

  ws2812.init()
  -- create a buffer, 60 LEDs with 3 colour bytes
  strip_buffer = ws2812.newBuffer(24, 3)
  -- init the effects module, set colour to red and start blinking
  ws2812_effects.init(strip_buffer)
  ws2812_effects.set_speed(100)
  ws2812_effects.set_delay(100)
  ws2812_effects.set_brightness(50)
  ws2812_effects.stop()
  setColours()
  setMode()
  ws2812_effects.start()

  local mytimer = tmr.create()

  mytimer:register(10000, tmr.ALARM_AUTO,
    function()
      tmr.softwd(600)
      setMode()
  end)

  mytimer:start()
end

local function disable_led()
  tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
    local pin = 4
    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, gpio.HIGH)
  end)
end

local function hslToRgb(h1, s1, l1)
  local r, g, b

  local h, s, l = h1 / 360, s1 / 100, l1 / 100
  if s == 0 then
    r, g, b = l, l, l -- achromatic
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

    r = hue2rgb(p, q, h + 1 / 3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1 / 3)
  end

  return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local function on(value)
  print("value,state.on,state.ct",value,state.on,state.ct)
  if value == true and state.on == true and state.ct == false then
    --ws2812.init(ws2812.MODE_SINGLE)
    --strip_buffer:fill(current_color.red, current_color.green, current_color.blue)
    print("Turning on RGB LED")
    --ws2812.write(strip_buffer)
    --disable_led()

    ws2812.init()
    -- create a buffer, 60 LEDs with 3 colour bytes
    strip_buffer = ws2812.newBuffer(24, 3)
    -- init the effects module, set colour to red and start blinking
    ws2812_effects.init(strip_buffer)
    ws2812_effects.stop()
    ws2812_effects.set_speed(100)
    ws2812_effects.set_delay(100)
    ws2812_effects.set_brightness(255)
    ws2812_effects.set_color(hslToRgb(state.hue, state.saturation, state.brightness))
    print(state.hue, state.saturation, state.brightness)
    print(hslToRgb(state.hue, state.saturation, state.brightness))
    ws2812_effects.set_mode("static")
    ws2812_effects.start()
    print("Turn off PWM mode")
    pwm.setup(config.pwm, 480, 0)
    pwm.start(config.pwm)
  elseif value == true and state.on == true and state.ct == true then
    print("Turning on White PWM LED")
    pwm.setup(config.pwm, 480, state.brightness)
    pwm.start(config.pwm)
  else
    --ws2812.init(ws2812.MODE_SINGLE)
    --strip_buffer:fill(0, 0, 0)
    --ws2812.write(strip_buffer)
    print("Turning off RGB LED")
    --disable_led()
    ws2812.init()
    -- create a buffer, 60 LEDs with 3 colour bytes
    strip_buffer = ws2812.newBuffer(24, 3)
    -- init the effects module, set colour to red and start blinking
    ws2812_effects.init(strip_buffer)
    ws2812_effects.stop()
    ws2812_effects.set_speed(100)
    ws2812_effects.set_delay(100)
    ws2812_effects.set_brightness(0)
    ws2812_effects.set_color(0, 0, 0)
    ws2812_effects.set_mode("static")
    ws2812_effects.start()
    print("Turn off PWM mode")
    pwm.setup(config.pwm, 480, 0)
    pwm.start(config.pwm)
  end
end

changeTimer:register(100, tmr.ALARM_SEMI, function() on(true) end)

function module.setHue(value)
  state.hue = value;
  state.ct = false;
  changeTimer:start()
end

function module.setOn(value)
  state.on = value;
  changeTimer:start()
end

function module.setSaturation(value)
  state.saturation = value;
  state.ct = false;
  changeTimer:start()
end

function module.setBrightness(value)
  state.brightness = value;
  changeTimer:start()
end

function module.setCT(value)
  state.ct = true;
  changeTimer:start()
end

function module.start(wsserver)
  --ws2812.init(ws2812.MODE_SINGLE)
  --strip_buffer = ws2812.newBuffer(24, 3)
  on(false)
  --demo()
  --ws2812_effects.set_color(255,255,255)
end





return module
