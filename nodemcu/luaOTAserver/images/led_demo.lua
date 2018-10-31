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
  if x == 0 then return 255, 0, 0
  elseif x == 1 then return 0, 255, 0
  elseif x == 2 then return 0, 0, 255
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

  mytimer:register(5000, tmr.ALARM_AUTO,
    function()
      tmr.softwd(600)
      setMode()
  end)

  mytimer:start()
end


demo()



return module
