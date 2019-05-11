--SAFETRIM

local module = {}
-- Options are DHT or DHT-YL, used by homebridge to determine if moisture data is valid.
module.Model = "CLED"
module.Version = "2.2"

module.ID = wifi.sta.gethostname()
module.mdnsName = "mculed"

-- LED state
module.ledState = 1 -- 0: fully disabled, 1: LEDs on, 2: Connected off (Boot/Error only)

-- GPIO Pins

module.ledRed = 0 -- gpio16
module.ledBlue = 4 -- gpio2

-- Costco LED strip

-- WS2812 = 4
module.pwm = 5
module.onButton = 1
module.colorButton = 2
module.ledCount = 50    -- 24 For costco Strip

return module
