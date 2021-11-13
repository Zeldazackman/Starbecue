local oldinit = init
local oldupdate = update
local olduninit = uninit

function init()
	oldinit()
end

local inited
function update(dt)
	if not inited then
		world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { spawner = entity.id() } )

		inited = true
	end
	oldupdate(dt)
end

function uninit()
	olduninit()
end
