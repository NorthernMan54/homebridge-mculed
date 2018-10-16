--SAFETRIM

local module = {}

local id = 0 -- always 0

local MPU6050SlaveAddress = 0x68

local MPU6050_REGISTER_SMPLRT_DIV = 0x19
local MPU6050_REGISTER_USER_CTRL = 0x6A
local MPU6050_REGISTER_PWR_MGMT_1 = 0x6B
local MPU6050_REGISTER_PWR_MGMT_2 = 0x6C
local MPU6050_REGISTER_CONFIG = 0x1A
local MPU6050_REGISTER_GYRO_CONFIG = 0x1B
local MPU6050_REGISTER_ACCEL_CONFIG = 0x1C
local MPU6050_REGISTER_FIFO_EN = 0x23
local MPU6050_REGISTER_INT_ENABLE = 0x38
local MPU6050_REGISTER_ACCEL_XOUT_H = 0x3B
local MPU6050_REGISTER_SIGNAL_PATH_RESET = 0x68

local AccelX = 0
local AccelY = 0
local AccelZ = 0

local GyroX = 0
local GyroY = 0
local GyroZ = 0

local sensitivity = 10

local movementA, movementG, Temperature = 0, 0, 0
local trigger = false
local status = nil



local function I2C_Write(deviceAddress, regAddress, data)
  i2c.start(id) -- send start condition
  if (i2c.address(id, deviceAddress, i2c.TRANSMITTER))-- set slave address and transmit direction
  then
    i2c.write(id, regAddress) -- write address to slave
    i2c.write(id, data) -- write data to slave
    i2c.stop(id) -- send stop condition
  else
    print("I2C_Write fails")
  end
end

local function I2C_Read(deviceAddress, regAddress, SizeOfDataToRead)
  local response = 0;
  i2c.start(id) -- send start condition
  if (i2c.address(id, deviceAddress, i2c.TRANSMITTER))-- set slave address and transmit direction
  then
    i2c.write(id, regAddress) -- write address to slave
    i2c.stop(id) -- send stop condition
    i2c.start(id) -- send start condition
    i2c.address(id, deviceAddress, i2c.RECEIVER)-- set slave address and receive direction
    response = i2c.read(id, SizeOfDataToRead) -- read defined length response from slave
    i2c.stop(id) -- send stop condition
    return response
  else
    print("I2C_Read fails")
  end
  return response
end

local function unsignTosigned16bit(num) -- convert unsigned 16-bit no. to signed 16-bit no.
  if num > 32768 then
    num = num - 65536
  end
  return num
end

local function MPU6050_Init() --configure MPU6050
  --tmr.delay(150000)
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_SMPLRT_DIV, 0x07)
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_PWR_MGMT_1, 0x01)
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_PWR_MGMT_2, 0x00)
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_CONFIG, 0x00)
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_GYRO_CONFIG, 0x00)-- set +/-250 degree/second full scale
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_ACCEL_CONFIG, 0x00)-- set +/- 2g full scale
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_FIFO_EN, 0x00)
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_INT_ENABLE, 0x00)
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_SIGNAL_PATH_RESET, 0x00)
  I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_USER_CTRL, 0x00)
end

local function _Round(X)
  return math.floor(math.abs(X / 800 ))
end

function module.sensitivity(data)
  sensitivity = data
  --print("Sensitivity",sensitivity)
end

function module.rawRead()

  local data = I2C_Read(MPU6050SlaveAddress, MPU6050_REGISTER_ACCEL_XOUT_H, 14)

  local _AccelX = AccelX
  local _AccelY = AccelY
  local _AccelZ = AccelZ
  local _GyroX = GyroX
  local _GyroY = GyroY
  local _GyroZ = GyroZ

  AccelX = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 1), 8), string.byte(data, 2))))
  AccelY = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 3), 8), string.byte(data, 4))))
  AccelZ = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 5), 8), string.byte(data, 6))))
  Temperature = unsignTosigned16bit(bit.bor(bit.lshift(string.byte(data, 7), 8), string.byte(data, 8)))
  GyroX = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 9), 8), string.byte(data, 10))))
  GyroY = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 11), 8), string.byte(data, 12))))
  GyroZ = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 13), 8), string.byte(data, 14))))

  Temperature = math.floor((Temperature / 340 + 36.53) * 10 + .5) / 10-- temperature formula

  movementA = _Round(_AccelX - AccelX) + _Round(_AccelY - AccelY) + _Round(_AccelZ - AccelZ)
  movementG = _Round(_GyroX - GyroX) + _Round(_GyroY - GyroY) + _Round(_GyroZ - GyroZ)

  trigger = false
  local _status = false

  if ( movementA + movementG > sensitivity )
  then
    -- Movement
    _status = true
  else
    -- Movement stopped
    _status = false
  end

  if ( status ~= _status )
  then
    trigger = true
  end

  status = _status

  return movementA, movementG, trigger, status, Temperature
end

function module.read( )
  -- Read sensors
  local gdstring = ""
  local motionstring = ""
  local tempstring = ""
  local currentstring = ""
  local filler = ""

  local movement = movementA + movementG
  local accelstring = " \"Accel\": "..movementA..", \"Gyro\": "..movementG..", \"Movement\": "..movement..
  ", \"Temperature\": "..Temperature
  accelstring = accelstring..", \"Motion\": "..tostring(trigger)

  local majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
  local upTime = tmr.time()

  local response =
  "{ \"Hostname\": \""..config.ID.."\", \"Model\": \""..config.Model.."\", \"Version\": \""..config.Version..
  "\", \"Uptime\": "..upTime..", \"Firmware\": \""..majorVer.."."..minorVer.."."..devVer.."\", \"Data\": { "..
    accelstring.." }}\n"

    --print(response)

  return response
end

function module.init()
    -- Initialize sensors
    package.loaded["mpu6050"]=nil
    i2c.setup(id, config.mpu6050sda, config.mpu6050scl, i2c.SLOW) -- initialize i2c
    MPU6050_Init()

end

return module
