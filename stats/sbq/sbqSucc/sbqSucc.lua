
function init()
end

function update(dt)
	local data = status.statusProperty("sbqSuccData")
	if data == nil then return end
	local distance = world.distance( data.destination, mcontroller.position() )
	local magnitude = world.magnitude( data.destination, mcontroller.position() )

	if magnitude > data.range then return end

	local percent = (magnitude/data.range)
	local powerMultiplier = (1 - percent)

	if (not ((data.direction < 0 and (distance[1] + data.direction) > 0) or (data.direction > 0 and (distance[1] + data.direction) < 0))) then
		effect.expire()
	end
	mcontroller.controlParameters({
		gravityMultiplier = math.max(0, percent - 0.5)
	})
	mcontroller.controlApproachVelocityAlongAngle(math.atan(distance[2], distance[1]), data.speed * powerMultiplier, data.force * powerMultiplier)
end

function uninit()
end
