sbq = {}
require("/scripts/SBQ_RPC_handling.lua")
function init()

	local config = root.assetJson("/sbqGeneral.config")
	local immune = (status.statusProperty("sbqPreyEnabled") or {}).transformImmunity or config.defaultPreyEnabled[world.entityType(entity.id())].transformImmunity
	if immune then return effect.expire() end
end
local inited
local source
function update(dt)
	sbq.checkRPCsFinished(dt)
	if not inited then
		source = status.statusProperty("sbqProjectileSource")
		if type(source) == "number" and world.entityExists(source) then
			status.setStatusProperty("sbqProjectileSource", nil)
			inited = true
			sbq.addRPC(world.sendEntityMessage(source, "sbqPotionDartGunData"), function (gotData)
				if gotData then
					if sbq[gotData.funcName] ~= nil then
						sbq[gotData.funcName](gotData.data)
					end
				end

			end, function ()
				effect.expire()
			end)
		end
	end
end

function uninit()
end

function sbq.transform(data)
	world.sendEntityMessage(entity.id(), "sbqMysteriousPotionTF", data, 5*60)
	world.spawnProjectile("sbqWarpInEffect", mcontroller.position(), entity.id(), { 0, 0 }, true)
	animator.playSound("activate")
end

function sbq.genderSwap()
	local table = {
		male = "female",
		female = "male"
	}
	data = status.statusProperty("speciesAnimOverrideData") or {}
	local originalGender = world.entityGender(entity.id())
	data.gender = table[(data.gender or originalGender)]
	local mysteriousPotionData = status.statusProperty("sbqMysteriousPotionTF") or {}
	mysteriousPotionData.gender = data.gender
	status.setStatusProperty("sbqMysteriousPotionTF", mysteriousPotionData)
	if data.gender == originalGender then
		data.gender = nil
	end
	status.setStatusProperty("speciesAnimOverrideData", data)

	local category = status.getPersistentEffects("speciesAnimOverride")
	status.clearPersistentEffects("speciesAnimOverride")
	if category[1] == nil then
		category = {"speciesAnimOverride"}
	end
	status.setPersistentEffects("speciesAnimOverride", category )
	world.spawnProjectile("sbqWarpInEffect", mcontroller.position(), entity.id(), { 0, 0 }, true)
	animator.playSound("activate")
end

function sbq.reversion()
	world.sendEntityMessage(entity.id(), "sbqEndMysteriousPotionTF")
	animator.playSound("activate")
end

function sbq.vehiclePred(vehicle)
	local currentData = status.statusProperty("sbqCurrentData") or {}
	sbq.addRPC(world.sendEntityMessage(entity.id(), "sbqLoadSettings", vehicle), function (settings)
		world.spawnVehicle( vehicle, mcontroller.position(), { driver = entity.id(), settings = settings, retrievePrey = currentData.id } )
		animator.playSound("activate")
	end, function ()
		world.spawnVehicle( vehicle, mcontroller.position(), { driver = entity.id(), retrievePrey = currentData.id } )
		animator.playSound("activate")
	end)
end
