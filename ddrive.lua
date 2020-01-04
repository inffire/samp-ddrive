script_name('ddrive')
script_description('kill the engine dec')
script_moonloader(018)
script_version_number(12)
script_author('inf')

local mem = require "memory"
local Vector3D = require "vector3d"

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

local NARDCORE_MODE = false

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

function main()
	repeat wait(100) until isSampAvailable()

	local stickBelow = 0.05
	if NARDCORE_MODE then stickBelow = 0.00 end

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
				local a, b = getPadState(0, 16), getPadState(0, 14)
				if a < 1 and b < 1 and not isCarInAirProper(car) then
					if isVehicleMovingForward(car) then
						setGameKeyState(16, 3)
					else
						setGameKeyState(14, 3)
					end
				end
			end
		end
		wait(1)
	end
end
