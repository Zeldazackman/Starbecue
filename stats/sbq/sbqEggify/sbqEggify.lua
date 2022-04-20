local replaceColors = {}
function init()
	local preyEnabled = sb.jsonMerge(root.assetJson("/sbqGeneral.config").defaultPreyEnabled[world.entityType(entity.id())], status.statusProperty("sbqPreyEnabled") or {})
	local currentData = status.statusProperty("sbqCurrentData") or {}
	if (not preyEnabled.enabled) or (preyEnabled.eggImmunity) or currentData.type == "prey" then
		effect.expire()
		return
	end

	local eggData = root.assetJson("/vehicles/sbq/sbqEgg/sbqEgg.vehicle")
	replaceColors = {
		math.random(1, #eggData.sbqData.replaceColors[1] - 1),
		math.random(1, #eggData.sbqData.replaceColors[2] - 1)
	}

	world.spawnProjectile("sbqWarpInEffect", mcontroller.position(), entity.id(), { 0, 0 }, true)
	eggSpawned = world.spawnVehicle("sbqEgg", mcontroller.position(), { driver = entity.id(), direction = mcontroller.facingDirection(), settings = { replaceColors = replaceColors, escapeDifficulty = -2 } })

	effect.expire()
end
