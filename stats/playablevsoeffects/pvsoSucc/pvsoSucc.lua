
function init()
end

function update(dt)
	local data = status.statusProperty("pvsoSuccData")
	if data == nil then return end

	local distance = world.distance( data.destination, mcontroller.position() )

	mcontroller.controlApproachVelocityAlongAngle(math.atan(distance[2], distance[1]), data.speed, data.force)
end

function uninit()
end
