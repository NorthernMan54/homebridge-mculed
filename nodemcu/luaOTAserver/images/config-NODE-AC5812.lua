--SAFETRIM

local module = {}
-- Options are DHT or DHT-YL, used by homebridge to determine if moisture data is valid.
--package.loaded["config-NODE-AC5812"]=nil
module.Model = "CLED"
module.Version = "2.2"

module.ID = wifi.sta.gethostname()
module.mdnsName = "mculed"

-- LED state
module.ledState = 0 -- 0: fully disabled, 1: LEDs on, 2: Connected off (Boot/Error only)

-- GPIO Pins

module.ledRed = 0   -- gpio16
module.ledBlue = 4  -- gpio2

-- Costco LED strip

-- WS2812 = 4
module.pwm = 5
module.button = 1
--module.pwr = 6

return module
