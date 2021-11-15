local oldinit = init
local oldupdate = update
local olduninit = uninit

function init()
	oldinit()
end

local occupantHolder
local inited
function update(dt)
	oldupdate(dt)

	if not occupantHolder then
		occupantHolder = world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), sb.jsonMerge({ spawner = entity.id() }) )
	end
end

function uninit()
	olduninit()
end

function handleInteract(args)
	local distance = entity.distanceToEntity(args.sourceId)
	if entity.entityInSight(args.sourceId) and ( math.abs(distance[1]) <= 5 ) and ( math.abs(distance[2]) <= 5 ) then
		requestEat(args.sourceId, "oralVore", "belly")
	end
end

function requestEat(prey, voreType, location)
	world.sendEntityMessage(occupantHolder, "requestEat", prey, voreType, location )
end

function requestUneat(prey, voreType)
	world.sendEntityMessage(occupantHolder, "requestUneat", prey, voreType )
end
