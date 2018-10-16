local module = {}

function module.start()
  -- Initial sensors

end

function module.read(motion, motionStatus, current)
  -- Read sensors
  package.loaded["sensors"] = nil
  local status
  local moist_value = 0
  local temp = -999
  local humi = -999
  local baro = -999
  local dew = -999
  local gdstring = ""
  local motionstring = ""
  local tempstring = ""
  local currentstring = ""
  local filler = ""
  local upTime = tmr.time()

  if string.find(config.Model, "BME") then
    local bme = require("bme")
    status, temp, humi, baro, dew = bme.read()
    if status ~= 0 then
      temp = -999
      humi = -999
      baro = -999
      dew = -999
    end
    tempstring = "\"Temperature\": "..temp..
    ", \"Humidity\": "..humi..", \"Moisture\": "..moist_value..
    ", \"Status\": "..status..", \"Barometer\": "..baro..", \"Dew\": "..dew
    filler = ","
  end
  if string.find(config.Model, "DHT") then
    status, temp, humi, temp_dec, humi_dec = dht.read(config.DHT22)
    if status ~= 0 then
      temp = -999
      humi = -999
      baro = -999
      dew = -999
    end
    tempstring = "\"Temperature\": "..temp..
    ", \"Humidity\": "..humi..", \"Moisture\": "..moist_value..
    ", \"Status\": "..status..", \"Barometer\": "..baro..", \"Dew\": "..dew
    filler = ","
  end

  if string.find(config.Model, "MS") then
    motionstring = filler.." \"Motion\": "..motion..", \"MotionStatus\": "..motionStatus.." "
  end

  if string.find(config.Model, "GD") then
    gdstring = filler.." \"CurrentDoorState\": "..CurrentDoorState.." "
  end

  if current ~= nil then
    if string.find(config.Model, "CU") then
      currentstring = filler.." \"Current\": "..current
    end
  end
  --      print("Heap Available:" .. node.heap())
  --      print("33")
  majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
  --      print("35")
  local response =
  "{ \"Hostname\": \""..config.ID.."\", \"Model\": \""..config.Model.."\", \"Version\": \""..config.Version..
  "\", \"Uptime\": "..upTime..", \"Firmware\": \""..majorVer.."."..minorVer.."."..devVer.."\", \"Data\": { "..
  tempstring..""..gdstring..""..motionstring..""..currentstring.." }}\n"
    --print(response)


    return response
  end

  return module
