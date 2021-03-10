function init()
	script.setUpdateDelta(1)
end

function update(dt)
	local distanceVector = entity.distanceToEntity(effect.sourceEntity())
	local angle = math.atan(distanceVector[1], distanceVector[2])
	mcontroller.controlApproachVelocityAlongAngle(angle, 100, 100, true)
end

function uninit()
end
