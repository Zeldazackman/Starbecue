function init()
	script.setUpdateDelta(5)
end

function update(dt)
	local distanceVector = entity.distanceToEntity(effect.sourceEntity())
	local angle = math.atan(distanceVector[1], distanceVector[2])
	mcontroller.controlApproachVelocityAlongAngle(angle, 10, 100, true)
end

function uninit()
end
