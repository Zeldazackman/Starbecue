
function update(dt)
	local data = status.statusProperty("sbqSetVelocityAngle")
	mcontroller.controlApproachVelocityAlongAngle( data.angle, data.velocity, 1000000)
end
