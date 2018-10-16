
-- Start of code
tmr.softwd(60)

print("Heap Available:  " .. node.heap()) -- 38984
config = require("config")
print("Heap Available: config " .. node.heap()) -- 37248 1500
mpu = require("mpu6050")
print("Heap Available: mpu6050 " .. node.heap()) -- 37248 1500
mpu.init()

local movementA, movementG, Temperature = 0,0,0
local interval = tmr.time()

tmr.create():alarm(100, tmr.ALARM_AUTO, function()
  local trigger = false
  local status = nil
  local _movementA, _movementG, _Temperature = mpu.rawRead()
  if ( _movementA + _movementG > 0 )
  then
    -- Movement
    if ( movementA + movementG == 0 )
    then
      trigger = true
      status = true
    end
  else
    -- Movement stopped
    if ( movementA + movementG > 0 )
    then
      trigger = true
      status = false
    end
  end
  movementA = _movementA
  movementG = _movementG

  if ( trigger )
  then
    mpu.read(status, tmr.time()-interval)
    interval = tmr.time()
  end
end)
