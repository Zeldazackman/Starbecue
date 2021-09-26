
function init()
end

function update(dt)
	local data = status.statusProperty("pvsoSuccData")
	if data == nil then return end
	local distance = world.distance( data.destination, mcontroller.position() )

	if (not ((data.direction < 0 and (distance[1] + data.direction) > 0) or (data.direction > 0 and (distance[1] + data.direction) < 0))) then
		effect.expire()
	end
	mcontroller.controlParameters({
		gravityMultiplier = 0
	})
	mcontroller.controlApproachVelocityAlongAngle(math.atan(distance[2], distance[1]), data.speed, data.force)
end

function uninit()
end
