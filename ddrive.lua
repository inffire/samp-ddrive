script_name('ddrive')
script_description('kill the engine dec')
script_moonloader(018)
script_version_number(13)
script_author('inf')

require "lib.moonloader"
require "lib.sampfuncs"

local mem = require "memory"
local Vector3D = require "vector3d"
local font = renderCreateFont("Arial", 10, FCR_BORDER)
local back = renderLoadTextureFromFile("moonloader/cruise.png")

local eVehicleType = {
	VEHICLE_AUTOMOBILE = 0,
	VEHICLE_MTRUCK = 1,
	VEHICLE_QUAD = 2,
	VEHICLE_HELI = 3,
	VEHICLE_PLANE = 4,
	VEHICLE_BOAT = 5,
	VEHICLE_TRAIN = 6,
	VEHICLE_FHELI = 7,
	VEHICLE_FPLANE = 8,
	VEHICLE_BIKE = 9,
	VEHICLE_BMX = 10,
	VEHICLE_TRAILER = 11
}

local SERVER_SPEED_MULTIPLER = 0.577

local KEY_BEGIN = VK_Q
local KEY_PAUSE = VK_E

local HARDCORE_MODE = false
local CRUISE_SPEED = 0
local CRUISE_STEP = 5
local CRUISE_PAUSED = false

function isVehicleMovingForward(vehicle)
	local pCar = getCarPointer(vehicle)
	if pCar then
		local pMatrix = mem.getuint32(pCar + 0x14)
		local heading = Vector3D(
			mem.getfloat(pMatrix + 0x10),
			mem.getfloat(pMatrix + 0x14),
			mem.getfloat(pMatrix + 0x18)
			)
		local speed = Vector3D(getCarSpeedVector(vehicle))
		return ( speed:dotProduct(heading) >= 0 )
	end
	return true
end

function getVehicleSubClass(vehicle)
	local subclass = 0
	local pCar = getCarPointer(vehicle)
	if pCar then subclass = mem.getuint32(pCar + 0x594) end
	return subclass
end

function procMouseWheel()
	local delta = getMousewheelDelta()
	if delta > 0 then
		for i=0, 110, CRUISE_STEP do
			if i > CRUISE_SPEED then
				CRUISE_SPEED = i
				if CRUISE_SPEED > 110 then CRUISE_SPEED = 110 end
				break
			end
		end
	end
	if delta < 0 then
		for i=0, 110, CRUISE_STEP do
			if i+0.01 >= CRUISE_SPEED then
				CRUISE_SPEED = i-CRUISE_STEP
				if CRUISE_SPEED < 0 then CRUISE_SPEED = 0 end
				break
			end
		end
	end
end

function procAccident(car)
	pCar = getCarPointer(car)
	if pCar ~= nil then
		local hit = mem.getfloat(pCar + 0xD8)
		if hit > 400 then CRUISE_PAUSED = true end
	end
end

function main()
	repeat wait(100) until isSampAvailable()

	local stickBelow = 0.05
	if HARDCORE_MODE then stickBelow = 0.00 end

	CRUISE_STEP = CRUISE_STEP / 3.4 / SERVER_SPEED_MULTIPLER

	while true do
		local car = nil
		if isCharInAnyCar(playerPed) then
			car = storeCarCharIsInNoSave(playerPed)
		end
		if car and getDriverOfCar(car) == playerPed and getCarSpeed(car) > stickBelow then
			local subclass = getVehicleSubClass(car)
			if subclass ~= eVehicleType.VEHICLE_HELI and
				subclass ~= eVehicleType.VEHICLE_PLANE and
				subclass ~= eVehicleType.VEHICLE_BOAT and
				subclass ~= eVehicleType.VEHICLE_BMX
			then

				if CRUISE_SPEED > 0 then
					local w, h = getScreenResolution()
					local color = 0xff62ba50
					if CRUISE_PAUSED then color = 0xccffff33 end
					renderFontDrawText(font, string.format("CRUISE @ %.0f kmph", CRUISE_SPEED * 3.4 * SERVER_SPEED_MULTIPLER), w * 0.6, h - 49, color)

					local w, h = getScreenResolution()
					renderDrawTexture(back, w * 0.3 - 32, h-90, 64, 64, 0.0, color)
				end

				if not sampIsCursorActive() and not isGamePaused() then
					if isKeyJustPressed(KEY_BEGIN) then
						if CRUISE_PAUSED then
							CRUISE_PAUSED = false
							CRUISE_SPEED = getCarSpeed(car)
						elseif not CRUISE_PAUSED and CRUISE_SPEED > 0 then
							CRUISE_SPEED = 0
						else
							CRUISE_SPEED = getCarSpeed(car)
							CRUISE_PAUSED = false
						end
					end

					if isKeyJustPressed(KEY_PAUSE) then CRUISE_PAUSED = not CRUISE_PAUSED end
				end

				procMouseWheel()
				procAccident(car)

				local current_speed = getCarSpeed(car)
				local function f(x)
					local a = 0.26
					local r = 1/(a*math.sqrt(2*math.pi))*math.pow((math.exp(-(x+6)^2/2*a^2)), 2)
					return r
				end
				local function g(x)
					return (f(0)-f(x))/f(0)
				end

				local a, b = getPadState(0, 16), getPadState(0, 14)
				if b > 0 and CRUISE_SPEED > 0 and not CRUISE_PAUSED then CRUISE_PAUSED = true end

				if a < 1 and b < 1 and not isCarInAirProper(car) then
					if isVehicleMovingForward(car) then
						if not CRUISE_PAUSED and CRUISE_SPEED > 0 and current_speed < CRUISE_SPEED then
							setGameKeyState(16, g(CRUISE_SPEED-current_speed) * 255)
						elseif not CRUISE_PAUSED and CRUISE_SPEED > 0 and current_speed > CRUISE_SPEED then
							-- pass
						else
							setGameKeyState(16, 3)
						end
					else
						setGameKeyState(14, 3)
					end
				end
			end
		end
		wait(1)
	end
end

function onExitScript()
	if font then renderReleaseFont(font) end
	if back then renderReleaseTexture(back) end
end