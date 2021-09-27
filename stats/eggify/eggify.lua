local smolPreyData = nil
local vsoSpawned = nil

function init()

	message.setHandler( "smolPreyData", function(_,_, seatindex, data, vso)
		world.sendEntityMessage( vso, "despawn", true ) -- no warpout
		smolPreyData = data
	end )

	local edibles = world.entityQuery( mcontroller.position(), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.edible", callScriptArgs = { entity.id(), 0, entity.id() }
	} )
	if edibles[1] == nil then
		vsoSpawned = world.spawnVehicle( "spovegg", mcontroller.position(), { driver = entity.id(), direction = mcontroller.facingDirection()} )
	end
end


function update(dt)
	if vsoSpawned == nil and smolPreyData ~= nil then
		vsoSpawned = world.spawnVehicle( "spovegg", mcontroller.position(), { driver = entity.id(), direction = mcontroller.facingDirection(), layer = smolPreyData} )
	end
end

function uninit()
end
