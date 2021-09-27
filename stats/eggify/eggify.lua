local smolPreyData = nil
local vsoSpawned = nil
local replaceColors = {}
function init()
	message.setHandler( "smolPreyData", function(_,_, seatindex, data, vso)
		world.sendEntityMessage( vso, "despawn", true ) -- no warpout
		smolPreyData = data
	end )

	replaceColors = {
		math.random(1, #root.assetJson("/vehicles/spov/egg/egg.vehicle").vso.replaceColors[1] - 1),
		math.random(1, #root.assetJson("/vehicles/spov/egg/egg.vehicle").vso.replaceColors[2] - 1)
	}

	local edibles = world.entityQuery( mcontroller.position(), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.edible", callScriptArgs = { entity.id(), 0, entity.id() }
	} )
	if edibles[1] == nil then
		world.spawnProjectile( "vsowarpineffect", mcontroller.position(), entity.id(), {0,0}, true)
		vsoSpawned = world.spawnVehicle( "spovegg", mcontroller.position(), { driver = entity.id(), direction = mcontroller.facingDirection(), settings = { replaceColors = replaceColors, escapeModifier = "easyEscape"}} )
	end
end


function update(dt)
	if vsoSpawned == nil and smolPreyData ~= nil then
		world.spawnProjectile( "vsowarpineffect", mcontroller.position(), entity.id(), {0,0}, true)
		vsoSpawned = world.spawnVehicle( "spovegg", mcontroller.position(), { driver = entity.id(), direction = mcontroller.facingDirection(), layer = smolPreyData, settings = { replaceColors = replaceColors, escapeModifier = "easyEscape"}} )
	end
end

function uninit()
end
