local smolPreyData = nil
local eggSpawned = nil
local replaceColors = {}
function init()
	message.setHandler( "sbqSmolPreyData", function(_,_, seatindex, data, predator)
		world.sendEntityMessage( predator, "despawn", true ) -- no warpout
		smolPreyData = data
	end )

	replaceColors = {
		math.random(1, #root.assetJson("/vehicles/sbq/sbqEgg/sbqEgg.vehicle").sbqData.replaceColors[1] - 1),
		math.random(1, #root.assetJson("/vehicles/sbq/sbqEgg/sbqEgg.vehicle").sbqData.replaceColors[2] - 1)
	}

	local edibles = world.entityQuery( mcontroller.position(), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.edible", callScriptArgs = { entity.id(), 0, entity.id(), 8, 8 }
	} )
	if edibles[1] == nil then
		world.spawnProjectile( "sbqWarpInEffect", mcontroller.position(), entity.id(), {0,0}, true)
		eggSpawned = world.spawnVehicle( "sbqEgg", mcontroller.position(), { driver = entity.id(), direction = mcontroller.facingDirection(), settings = { replaceColors = replaceColors, escapeModifier = "easyEscape"}} )
	end
end


function update(dt)
	if eggSpawned == nil and smolPreyData ~= nil then
		world.spawnProjectile( "sbqWarpOutEffect", mcontroller.position(), entity.id(), {0,0}, true)
		eggSpawned = world.spawnVehicle( "sbqEgg", mcontroller.position(), { driver = entity.id(), direction = mcontroller.facingDirection(), layer = smolPreyData, settings = { replaceColors = replaceColors, escapeModifier = "easyEscape"}} )
	end
end

function uninit()
end
