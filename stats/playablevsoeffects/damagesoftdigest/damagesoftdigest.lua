function init()
	script.setUpdateDelta(5)
	self.powerMultiplier = effect.duration()

	status.removeEphemeralEffect("damagedigest")
	status.removeEphemeralEffect("displaydamagesoftdigest")
	status.removeEphemeralEffect("displaydamagedigest")

end

function update(dt)

	local health = world.entityHealth(entity.id())

	if health[1] <= 1 then
	status.setResource("health", 1)
	return
	end


	if health[1] > ( 0.01 * dt * self.powerMultiplier) then
	status.modifyResourcePercentage("health", -0.01 * dt * self.powerMultiplier)
	end
end

function uninit()

end
